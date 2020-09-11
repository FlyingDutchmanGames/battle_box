defmodule BattleBoxWeb.Sockets.BattleBoxSocketTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{GameEngine, User}
  import BattleBox.GameEngine, only: [get_connection: 2]

  @bot_name "some-bot-name"

  defmacrop assert_recieve_msg(conn, msg) do
    quote do
      assert_receive({:gun_ws, ^unquote(conn), _ref, {:text, received_msg}})
      assert unquote(msg) = Jason.decode!(received_msg)
    end
  end

  setup %{test: name} do
    {:ok, _pid} = GameEngine.start_link(name: name)
    GameEngine.Provider.set_game_engine(name)
    on_exit(fn -> GameEngine.Provider.reset!() end)
    GameEngine.names(name)
  end

  setup do
    {:ok, user} = create_user()
    {:ok, key} = create_key(user: user)
    %{user: user, key: key}
  end

  setup context do
    %{connection_request: %{"token" => context.key.token, "bot" => @bot_name}}
  end

  test "You get an invalid json error message" do
    {:ok, conn} = connect()
    :ok = :gun.ws_send(conn, {:text, "{NOT VALID JSON!!!"})
    assert_recieve_msg(conn, %{"error" => "invalid_json"})
  end

  test "you can ping the socket with the json encoded \"ping\"" do
    {:ok, conn} = connect()
    :ok = send_msg(conn, "PING")
    assert_recieve_msg(conn, "PONG")
  end

  test "you can connect and the process will register", context do
    {:ok, conn} = connect()
    :ok = send_msg(conn, context.connection_request)

    assert_recieve_msg(conn, %{"connection_id" => connection_id})

    assert %{started_at: started_at} = get_connection(context.game_engine, connection_id)
    assert DateTime.diff(DateTime.utc_now(), started_at) < 2
  end

  test "closing the websocket connection causes the connection process to die", context do
    {:ok, conn} = connect()
    :ok = send_msg(conn, context.connection_request)
    assert_recieve_msg(conn, %{"connection_id" => connection_id})
    %{pid: pid} = get_connection(context.game_engine, connection_id)
    ref = Process.monitor(pid)
    :ok = :gun.close(conn)
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
  end

  test "You can join as a bot", context do
    {:ok, conn} = connect()
    :ok = send_msg(conn, context.connection_request)

    assert_recieve_msg(conn, %{
      "status" => "idle",
      "connection_id" => _connection_id,
      "bot_server_id" => <<_::288>>,
      "watch" => %{"bot" => _, "user" => _}
    })
  end

  test "trying to join while your user is banned is an error", context do
    Repo.update_all(User, set: [is_banned: true])
    {:ok, conn} = connect()
    :ok = send_msg(conn, context.connection_request)
    assert_recieve_msg(conn, %{"error" => %{"user" => ["User is banned"]}})
  end

  test "you get notified if the player server dies and the connection closes", context do
    {:ok, conn} = connect()
    :ok = send_msg(conn, context.connection_request)
    assert_recieve_msg(conn, %{"connection_id" => connection_id})

    [%{pid: bot_server_pid}] =
      GameEngine.get_bot_servers_with_user_id(context.game_engine, context.user.id)

    %{pid: connection_pid} = get_connection(context.game_engine, connection_id)
    Process.monitor(connection_pid)
    Process.exit(bot_server_pid, :kill)

    assert_recieve_msg(conn, %{"error" => "bot_instance_failure"})
    assert_receive {:DOWN, _, _, ^connection_pid, :normal}
  end

  test "if you try to join with a bad token, it fails" do
    {:ok, conn} = connect()
    :ok = send_msg(conn, %{"token" => "FAKE", "bot" => @bot_name})
    assert_recieve_msg(conn, %{"error" => %{"token" => ["Invalid API Key"]}})
  end

  setup do
    {:ok, arena} = marooned_arena()

    %{
      arena: arena,
      start_matchmaking_request: %{"action" => "start_match_making", "arena" => arena.name}
    }
  end

  test "you can start a practice match", context do
    %{1 => %{conn: conn}} = connections(context, 1)

    send_msg(conn, %{
      "action" => "practice",
      "arena" => context.arena.name
    })

    assert_recieve_msg(conn, %{"status" => "match_making"})
    assert_recieve_msg(conn, %{"request_type" => "game_request"})
  end

  test "asking to practice against a nonsense opponent errors", context do
    %{1 => %{conn: conn}} = connections(context, 1)

    send_msg(conn, %{
      "action" => "practice",
      "arena" => context.arena.name,
      "opponent" => "nonsense"
    })

    Process.sleep(50)

    assert_recieve_msg(conn, %{
      "error" => %{"opponent" => ["No opponent matching (\"nonsense\")"]}
    })
  end

  test "you can join a matchmaking queue", context do
    %{1 => %{conn: conn}} = connections(context, 1)
    send_msg(conn, context.start_matchmaking_request)
    assert_recieve_msg(conn, %{"status" => "match_making"})
  end

  test "two players can get matched in a game", context do
    %{1 => %{conn: p1}, 2 => %{conn: p2}} = connections(context, 2)

    for conn <- [p1, p2],
        do: send_msg(conn, context.start_matchmaking_request)

    :ok = GameEngine.force_match_make(context.game_engine)

    for conn <- [p1, p2] do
      assert_recieve_msg(conn, %{"status" => "match_making"})

      assert_recieve_msg(conn, %{
        "game_info" => %{
          "game_id" => <<_::288>> = game_id,
          "player" => _,
          "settings" => %{}
        },
        "request_type" => "game_request"
      })
    end
  end

  test "the game gets cancelled if the other player dies", context do
    %{1 => %{conn: p1}, 2 => %{conn: p2}} = connections(context, 2)

    for conn <- [p1, p2],
        do: send_msg(conn, context.start_matchmaking_request)

    assert_recieve_msg(p1, %{"status" => "match_making"})

    :ok = GameEngine.force_match_make(context.game_engine)

    assert_recieve_msg(p1, %{
      "request_type" => "game_request",
      "game_info" => %{"game_id" => game_id}
    })

    Process.exit(p2, :kill)
    assert_recieve_msg(p1, %{"game_id" => ^game_id, "info" => "game_cancelled"})
  end

  test "if one accepts and the other rejects, the game is cancelled", context do
    %{1 => %{conn: p1}, 2 => %{conn: p2}} = connections(context, 2)

    for conn <- [p1, p2], do: send_msg(conn, context.start_matchmaking_request)
    for conn <- [p1, p2], do: assert_recieve_msg(conn, %{"status" => "match_making"})
    :ok = GameEngine.force_match_make(context.game_engine)

    [game_id, game_id] =
      for conn <- [p1, p2],
          %{"game_info" => %{"game_id" => game_id}} = assert_recieve_msg(conn, _msg),
          do: game_id

    send_msg(p1, %{"action" => "accept_game", "game_id" => game_id})
    send_msg(p1, %{"action" => "reject_game", "game_id" => game_id})
  end

  test "you can accept a game", context do
    %{1 => %{conn: p1}, 2 => %{conn: p2}} = connections(context, 2)

    for conn <- [p1, p2], do: send_msg(conn, context.start_matchmaking_request)
    for conn <- [p1, p2], do: assert_recieve_msg(conn, %{"status" => "match_making"})
    :ok = GameEngine.force_match_make(context.game_engine)

    [game_id, game_id] =
      for conn <- [p1, p2],
          %{"game_info" => %{"game_id" => game_id}} = assert_recieve_msg(conn, _msg),
          do: game_id

    for conn <- [p1, p2], do: send_msg(conn, %{"action" => "accept_game", "game_id" => game_id})

    for conn <- [p1, p2],
        do:
          assert_recieve_msg(conn, %{
            "request_type" => "commands_request",
            "commands_request" => %{
              "game_id" => ^game_id,
              "request_id" => _,
              "game_state" => %{"turn" => _}
            }
          })
  end

  test "commands with the wrong id get a message saying they're invalid", context do
    %{1 => %{conn: p1}} = start_game(context)

    assert_recieve_msg(p1, %{"commands_request" => %{}})

    send_msg(p1, %{
      "action" => "send_commands",
      "request_id" => "GIBBERISH!!!!!!!!!",
      "commands" => []
    })

    assert_recieve_msg(p1, %{
      "error" => "invalid_commands_submission",
      "request_id" => "GIBBERISH!!!!!!!!!"
    })
  end

  test "playing the game", context do
    %{1 => %{conn: p1, game_id: game_id}, 2 => %{conn: p2, game_id: game_id}} =
      start_game(context)

    commands = fn id -> %{"action" => "send_commands", "request_id" => id, "commands" => []} end

    turns =
      Stream.unfold(:unused, fn _ ->
        with %{"commands_request" => %{"request_id" => id}} <- assert_recieve_msg(p1, _msg),
             :ok <- send_msg(p1, commands.(id)),
             %{"commands_request" => %{"request_id" => id}} <- assert_recieve_msg(p2, _msg),
             :ok <- send_msg(p2, commands.(id)) do
          {:ok, :ok}
        else
          %{
            "info" => "game_over",
            "game_id" => ^game_id,
            "result" => %{"1" => _, "2" => _},
            "watch" => "http://localhost:4002/games/" <> ^game_id
          } ->
            nil
        end
      end)
      |> Enum.to_list()

    assert length(turns) > 1
  end

  defp start_game(context) do
    conns = %{1 => %{conn: p1}, 2 => %{conn: p2}} = connections(context, 2)

    for conn <- [p1, p2], do: send_msg(conn, context.start_matchmaking_request)
    for conn <- [p1, p2], do: assert_recieve_msg(conn, %{"status" => "match_making"})
    :ok = GameEngine.force_match_make(context.game_engine)

    conns =
      for {_conn_number, %{conn: conn}} <- conns, into: %{} do
        assert_recieve_msg(conn, %{"game_info" => %{"game_id" => game_id, "player" => player}})
        {player, %{conn: conn, game_id: game_id}}
      end

    for {_, %{conn: conn, game_id: game_id}} <- conns,
        do: send_msg(conn, %{"action" => "accept_game", "game_id" => game_id})

    conns
  end

  defp connections(context, number) do
    for player <- 1..number, into: %{} do
      {:ok, conn} = connect()
      send_msg(conn, %{"bot" => @bot_name, "token" => context.key.token})
      assert_recieve_msg(conn, %{"connection_id" => connection_id})
      {player, %{conn: conn, connection_id: connection_id}}
    end
  end

  defp send_msg(conn, msg) do
    msg = Jason.encode!(msg)
    :ok = :gun.ws_send(conn, {:text, msg})
  end

  defp connect do
    {:ok, conn} = :gun.open('localhost', 4002)
    {:ok, :http} = :gun.await_up(conn)
    ref = :gun.ws_upgrade(conn, "/battle_box/websocket")

    receive do
      {:gun_upgrade, ^conn, ^ref, ["websocket"], _headers} -> :upgraded
    after
      1000 -> raise "FAILED TO CONNECT"
    end

    {:ok, conn}
  end
end
