defmodule BattleBox.TcpConnectionServer.ConnectionHandlerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{User, GameEngine, TcpConnectionServer}
  import BattleBox.GameEngine, only: [get_connection: 2]
  import BattleBox.Connection.Message

  @ip {127, 0, 0, 1}
  @bot_name "bot-name"
  @arena_name "arena-name"
  @user_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup %{game_engine: game_engine, test: name} do
    ranch_name = :"#{name}-ranch"

    {:ok, _} =
      Supervisor.start_link(
        [{TcpConnectionServer, port: 0, game_engine: game_engine, name: ranch_name}],
        strategy: :one_for_one
      )

    %{port: :ranch.get_port(ranch_name)}
  end

  setup do
    {:ok, user} = create_user(id: @user_id)
    {:ok, arena} = marooned_arena(user: user, arena_name: @arena_name, command_time_minimum_ms: 1)
    {:ok, key} = create_key(user: user)

    %{user: user, arena: arena, key: key}
  end

  setup context do
    %{
      connection_request: encode(%{"token" => context.key.token, "bot" => @bot_name}),
      start_matchmaking_request:
        encode(%{"action" => "start_match_making", "arena" => context.arena.name})
    }
  end

  test "you can connect and the process will register", context do
    {:ok, socket} = connect(context.port)

    :ok = :gen_tcp.send(socket, context.connection_request)
    assert_receive {:tcp, ^socket, msg}
    assert %{"connection_id" => connection_id} = Jason.decode!(msg)
    assert %{started_at: started_at} = get_connection(context.game_engine, connection_id)
    assert DateTime.diff(DateTime.utc_now(), started_at) < 2
  end

  test "closing the tcp connection causes the connection process to die", context do
    {:ok, socket} = connect(context.port)
    :ok = :gen_tcp.send(socket, context.connection_request)
    assert_receive {:tcp, ^socket, msg}
    assert %{"connection_id" => connection_id} = Jason.decode!(msg)
    %{pid: pid} = get_connection(context.game_engine, connection_id)
    ref = Process.monitor(pid)
    :ok = :gen_tcp.close(socket)
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
  end

  test "You can PING the server", context do
    {:ok, socket} = connect(context.port)
    :ok = :gen_tcp.send(socket, encode("PING"))
    assert_receive {:tcp, ^socket, "\"PONG\""}
  end

  describe "joining as a bot" do
    setup context do
      {:ok, socket} = connect(context.port)
      %{socket: socket}
    end

    test "you can join", %{socket: socket, key: %{token: token}} do
      bot_connect_req = encode(%{"token" => token, "bot" => @bot_name})

      :ok = :gen_tcp.send(socket, bot_connect_req)
      assert_receive {:tcp, ^socket, msg}

      assert %{
               "status" => "idle",
               "connection_id" => _connection_id,
               "bot_server_id" => <<_::288>>,
               "watch" => watch_links
             } = Jason.decode!(msg)

      assert %{"bot" => _, "user" => _} = watch_links
    end

    test "trying to join while your user is banned is an error", %{socket: socket} = context do
      Repo.update_all(User, set: [is_banned: true])
      :ok = :gen_tcp.send(socket, context.connection_request)
      assert_receive {:tcp, ^socket, msg}
      assert %{"error" => %{"user" => ["User is banned"]}} = Jason.decode!(msg)
    end

    test "you get notified if the player server dies and the connection closes",
         %{socket: socket} = context do
      :ok = :gen_tcp.send(socket, context.connection_request)

      assert_receive {:tcp, ^socket, msg}
      assert %{"connection_id" => connection_id} = Jason.decode!(msg)
      [player_pid] = Registry.select(context.bot_registry, [{{:_, :"$1", :_}, [], [:"$1"]}])
      [{connection_pid, _}] = Registry.lookup(context.connection_registry, connection_id)
      Process.monitor(connection_pid)
      Process.exit(player_pid, :kill)

      assert_receive {:tcp, ^socket, msg}
      assert %{"error" => "bot_instance_failure"} = Jason.decode!(msg)
      assert_receive {:DOWN, _, _, ^connection_pid, :normal}
    end

    test "if you try to join with a bad token it fails", %{socket: socket} do
      bot_connect_req = encode(%{"token" => "FAKE", "bot" => @bot_name})

      :ok = :gen_tcp.send(socket, bot_connect_req)
      assert_receive {:tcp, ^socket, msg}
      assert %{"error" => %{"token" => ["Invalid API Key"]}} = Jason.decode!(msg)
    end
  end

  describe "matching_making" do
    setup context do
      for player <- [:p1, :p2] do
        {:ok, socket} = connect(context.port)

        join_request =
          encode(%{
            "token" => context.key.token,
            "bot" => @bot_name
          })

        :ok = :gen_tcp.send(socket, join_request)
        assert_receive {:tcp, ^socket, msg}
        %{"connection_id" => connection_id} = Jason.decode!(msg)

        {player, %{socket: socket, connection_id: connection_id}}
      end
      |> Map.new()
    end

    test "you can join a matchmaking queue", %{p1: %{socket: socket}} = context do
      :ok = :gen_tcp.send(socket, context.start_matchmaking_request)
      assert_receive {:tcp, ^socket, resp}

      %{"status" => "match_making"} = Jason.decode!(resp)
    end

    test "two players can get matched to a game",
         %{p1: %{socket: p1}, p2: %{socket: p2}} = context do
      :ok = :gen_tcp.send(p1, context.start_matchmaking_request)
      assert_receive {:tcp, ^p1, _started_matchmaking}

      :ok = :gen_tcp.send(p2, context.start_matchmaking_request)
      assert_receive {:tcp, ^p2, _started_matchmaking}

      :ok = GameEngine.force_match_make(context.game_engine)
      assert_receive {:tcp, ^p1, game_request}
      assert_receive {:tcp, ^p2, _game_request}

      assert %{
               "game_info" => %{
                 "game_id" => <<_::288>>,
                 "game_type" => "marooned",
                 "player" => _,
                 "players" => %{
                   "1" => %{
                     "bot" => %{
                       "name" => "bot-name",
                       "user" => %{"username" => _, "avatar_url" => _}
                     }
                   },
                   "2" => %{
                     "bot" => %{
                       "name" => "bot-name",
                       "user" => %{"username" => _, "avatar_url" => _}
                     }
                   }
                 },
                 "settings" => %{
                   "rows" => 10,
                   "cols" => 10
                 }
               },
               "request_type" => "game_request"
             } = Jason.decode!(game_request)
    end

    test "you can get put in a practice match", %{p1: %{socket: p1}, arena: arena} do
      :ok =
        :gen_tcp.send(
          p1,
          encode(%{"action" => "practice", "arena" => arena.name})
        )

      assert_receive {:tcp, ^p1, start_match_making}
      assert %{"status" => "match_making"} = Jason.decode!(start_match_making)
      assert_receive {:tcp, ^p1, game_request}
      assert %{"request_type" => "game_request"} = Jason.decode!(game_request)
    end

    test "asking for a nonsense opponent will give you an error", %{p1: %{socket: p1}} do
      :ok =
        :gen_tcp.send(
          p1,
          encode(%{"action" => "practice", "arena" => @arena_name, "opponent" => "nonsense"})
        )

      assert_receive {:tcp, ^p1, opponent_error}

      assert %{"error" => %{"opponent" => ["No opponent matching (\"nonsense\")"]}} =
               Jason.decode!(opponent_error)
    end
  end

  describe "game acceptance" do
    setup context do
      for player <- [:p1, :p2] do
        {:ok, socket} = connect(context.port)

        join_request =
          encode(%{
            "token" => context.key.token,
            "bot" => @bot_name
          })

        :ok = :gen_tcp.send(socket, join_request)
        assert_receive {:tcp, ^socket, msg}
        %{"connection_id" => connection_id} = Jason.decode!(msg)
        :ok = :gen_tcp.send(socket, context.start_matchmaking_request)
        assert_receive {:tcp, ^socket, _msg}
        {player, %{socket: socket, connection_id: connection_id}}
      end
      |> Map.new()
    end

    test "you get a game_cancelled if the other player dies",
         %{p1: %{socket: p1}, p2: %{socket: p2}} = context do
      :ok = GameEngine.force_match_make(context.game_engine)
      Process.sleep(10)
      :ok = :gen_tcp.close(p2)
      assert_receive {:tcp, ^p1, game_req}

      assert %{"request_type" => "game_request", "game_info" => %{"game_id" => game_id}} =
               Jason.decode!(game_req)

      assert_receive {:tcp, ^p1, game_cancelled}
      assert %{"game_id" => ^game_id, "info" => "game_cancelled"} = Jason.decode!(game_cancelled)
    end

    test "if one accepts and the other rejects the game is cancelled",
         %{p1: %{socket: p1}, p2: %{socket: p2}} = context do
      :ok = GameEngine.force_match_make(context.game_engine)
      assert_receive {:tcp, ^p1, game_req}
      assert_receive {:tcp, ^p2, _game_req}
      assert %{"game_info" => %{"game_id" => game_id}} = Jason.decode!(game_req)
      accept_game = %{"action" => "accept_game", "game_id" => game_id}
      reject_game = %{"action" => "reject_game", "game_id" => game_id}
      :ok = :gen_tcp.send(p1, encode(accept_game))
      :ok = :gen_tcp.send(p2, encode(reject_game))
      assert_receive {:tcp, ^p1, game_cancelled}
      assert_receive {:tcp, ^p2, ^game_cancelled}
      assert %{"game_id" => ^game_id, "info" => "game_cancelled"} = Jason.decode!(game_cancelled)
    end

    test "you can accept a game", %{p1: %{socket: p1}, p2: %{socket: p2}} = context do
      :ok = GameEngine.force_match_make(context.game_engine)
      assert_receive {:tcp, ^p1, game_req}

      assert %{"request_type" => "game_request", "game_info" => %{"game_id" => game_id}} =
               Jason.decode!(game_req)

      assert_receive {:tcp, ^p2, game_req}

      assert %{"request_type" => "game_request", "game_info" => %{"game_id" => ^game_id}} =
               Jason.decode!(game_req)

      accept_game = %{"action" => "accept_game", "game_id" => game_id}
      :ok = :gen_tcp.send(p1, encode(accept_game))
      :ok = :gen_tcp.send(p2, encode(accept_game))

      assert_receive {:tcp, _conn, move_req}

      assert %{
               "request_type" => "commands_request",
               "commands_request" => %{
                 "game_id" => ^game_id,
                 "request_id" => <<_::288>>,
                 "game_state" => _,
                 "score" => %{
                   "1" => _,
                   "2" => _
                 }
               }
             } = Jason.decode!(move_req)
    end
  end

  describe "commands requests" do
    setup context do
      players =
        for player <- [:p1, :p2] do
          {:ok, socket} = connect(context.port)

          join_request =
            encode(%{
              "token" => context.key.token,
              "bot" => @bot_name
            })

          :ok = :gen_tcp.send(socket, join_request)
          assert_receive {:tcp, ^socket, msg}
          %{"connection_id" => connection_id} = Jason.decode!(msg)
          :ok = :gen_tcp.send(socket, context.start_matchmaking_request)
          assert_receive {:tcp, ^socket, _info_msg}
          {player, %{socket: socket, connection_id: connection_id}}
        end
        |> Map.new()

      %{p1: %{socket: p1}, p2: %{socket: p2}} = players
      :ok = GameEngine.force_match_make(context.game_engine)

      assert_receive {:tcp, ^p1, game_req}
      assert %{"game_info" => %{"game_id" => game_id}} = Jason.decode!(game_req)
      assert_receive {:tcp, ^p2, _game_req}

      accept_game = %{"action" => "accept_game", "game_id" => game_id}
      :ok = :gen_tcp.send(p1, encode(accept_game))
      :ok = :gen_tcp.send(p2, encode(accept_game))

      Map.merge(players, %{game_id: game_id})
    end

    test "commands with the wrong id get the messages that they were invalid" do
      assert_receive {:tcp, conn, commands_request}
      incorrect_request_id = Ecto.UUID.generate()
      %{"commands_request" => _} = Jason.decode!(commands_request)
      :ok = :gen_tcp.send(conn, empty_commands_msg(incorrect_request_id))
      assert_receive {:tcp, _conn, error}

      assert %{"error" => "invalid_commands_submission", "request_id" => ^incorrect_request_id} =
               Jason.decode!(error)
    end

    test "playing the game", %{game_id: game_id} do
      turns =
        Stream.unfold(:ok, fn _ ->
          receive do
            {:tcp, conn, message} ->
              case Jason.decode!(message) do
                %{"commands_request" => %{"request_id" => request_id}} ->
                  :gen_tcp.send(conn, empty_commands_msg(request_id))
                  {:turn, :ok}

                %{"info" => "debug"} ->
                  {:debug, :ok}

                %{
                  "info" => "game_over",
                  "game_id" => ^game_id,
                  "result" => %{"1" => _, "2" => _},
                  "watch" => "http://localhost:4002/games/" <> ^game_id
                } ->
                  nil
              end
          after
            150 -> flunk("Something went wrong")
          end
        end)
        |> Enum.to_list()

      assert length(for :turn <- turns, do: :turn) > 2
    end
  end

  defp empty_commands_msg(commands_request_id) do
    encode(%{
      "action" => "send_commands",
      "request_id" => commands_request_id,
      "commands" => []
    })
  end

  defp connect(port) do
    :gen_tcp.connect(@ip, port, [:binary, active: true, packet: 2, recbuf: 65536])
  end
end
