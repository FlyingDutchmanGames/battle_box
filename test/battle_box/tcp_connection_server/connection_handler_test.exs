defmodule BattleBox.TcpConnectionServer.ConnectionHandlerTest do
  use BattleBox.DataCase
  alias BattleBox.{ApiKey, Bot, User, GameEngine, TcpConnectionServer}
  import BattleBox.GameEngine, only: [get_connection: 2]
  import BattleBox.Connection.Message

  @ip {127, 0, 0, 1}
  @bot_name "bot-name"
  @lobby_name "lobby-name"
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

    {:ok, lobby} =
      robot_game_lobby(user: user, lobby_name: @lobby_name, command_time_minimum_ms: 1)

    {:ok, bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: @bot_name})
      |> Repo.insert()

    {:ok, key} =
      user
      |> Ecto.build_assoc(:api_keys)
      |> ApiKey.changeset(%{name: "test-key"})
      |> Repo.insert()

    %{user: user, lobby: lobby, bot: bot, key: key}
  end

  setup context do
    %{
      connection_request:
        encode(%{"token" => context.key.token, "lobby" => context.lobby.name, "bot" => @bot_name}),
      start_matchmaking_request: encode(%{"action" => "start_match_making"})
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

  describe "joining a lobby as a bot" do
    setup context do
      {:ok, socket} = connect(context.port)
      %{socket: socket}
    end

    test "you can join", %{socket: socket, key: %{token: token}} do
      bot_connect_req = encode(%{"token" => token, "lobby" => @lobby_name, "bot" => @bot_name})

      :ok = :gen_tcp.send(socket, bot_connect_req)
      assert_receive {:tcp, ^socket, msg}

      assert %{
               "status" => "idle",
               "connection_id" => connection_id,
               "bot_server_id" => <<_::288>>,
               "user_id" => @user_id
             } = Jason.decode!(msg)
    end

    test "trying to join a lobby that doesn't exist is an error", %{
      socket: socket,
      bot: bot,
      key: key
    } do
      bot_connect_req = encode(%{"token" => key.token, "lobby" => "FAKE", "bot" => bot.name})
      :ok = :gen_tcp.send(socket, bot_connect_req)
      assert_receive {:tcp, ^socket, msg}
      assert %{"error" => %{"lobby" => ["Lobby not found"]}} = Jason.decode!(msg)
    end

    test "trying to join while your user is banned is an error", %{
      socket: socket,
      bot: bot,
      key: key
    } do
      Repo.update_all(User, set: [is_banned: true])
      bot_connect_req = encode(%{"token" => key.token, "lobby" => @lobby_name, "bot" => bot.name})
      :ok = :gen_tcp.send(socket, bot_connect_req)
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

    test "if you try to join as a bot that doesn't exist it fails", %{socket: socket} = context do
      bot_connect_req =
        encode(%{"token" => "FAKE", "lobby" => context.lobby.name, "bot" => @bot_name})

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
            "lobby" => context.lobby.name,
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
                 "game_id" => <<_::288>> = game_id,
                 "player" => _,
                 "settings" => %{
                   "attack_damage" => _,
                   "collision_damage" => _,
                   "max_turns" => _,
                   "robot_hp" => _,
                   "spawn_every" => _,
                   "spawn_per_player" => _,
                   "terrain_base64" => _
                 }
               },
               "request_type" => "game_request"
             } = Jason.decode!(game_request)
    end
  end

  describe "game acceptance" do
    setup context do
      for player <- [:p1, :p2] do
        {:ok, socket} = connect(context.port)

        join_request =
          encode(%{
            "token" => context.key.token,
            "lobby" => context.lobby.name,
            "bot" => @bot_name
          })

        :ok = :gen_tcp.send(socket, join_request)
        assert_receive {:tcp, ^socket, msg}
        %{"connection_id" => connection_id} = Jason.decode!(msg)
        :ok = :gen_tcp.send(socket, context.start_matchmaking_request)
        assert_receive {:tcp, ^socket, msg}
        {player, %{socket: socket, connection_id: connection_id}}
      end
      |> Map.new()
    end

    test "you get a game_cancelled if the other player dies",
         %{p1: %{socket: p1}, p2: %{socket: p2}} = context do
      :ok = GameEngine.force_match_make(context.game_engine)
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

      assert_receive {:tcp, ^p1, move_req}

      assert %{
               "request_type" => "commands_request",
               "commands_request" => %{
                 "game_id" => ^game_id,
                 "request_id" => <<_::288>>,
                 "game_state" => _
               }
             } = Jason.decode!(move_req)

      assert_receive {:tcp, ^p2, move_req}

      assert %{
               "request_type" => "commands_request",
               "commands_request" => %{"game_id" => ^game_id}
             } = Jason.decode!(move_req)
    end
  end

  describe "moves requests" do
    setup context do
      players =
        for player <- [:p1, :p2] do
          {:ok, socket} = connect(context.port)

          join_request =
            encode(%{
              "token" => context.key.token,
              "lobby" => context.lobby.name,
              "bot" => context.bot.name
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
      assert_receive {:tcp, ^p2, game_req}

      accept_game = %{"action" => "accept_game", "game_id" => game_id}
      :ok = :gen_tcp.send(p1, encode(accept_game))
      :ok = :gen_tcp.send(p2, encode(accept_game))

      Map.merge(players, %{game_id: game_id})
    end

    test "commands with the wrong id get the messages that they were invalid", %{
      p1: %{socket: p1}
    } do
      assert_receive {:tcp, ^p1, commands_request}
      incorrect_request_id = Ecto.UUID.generate()
      %{"commands_request" => _} = Jason.decode!(commands_request)
      :ok = :gen_tcp.send(p1, empty_commands_msg(incorrect_request_id))
      assert_receive {:tcp, ^p1, error}

      assert %{"error" => "invalid_commands_submission", "request_id" => ^incorrect_request_id} =
               Jason.decode!(error)
    end

    test "playing the game", %{p1: %{socket: p1}, p2: %{socket: p2}, game_id: game_id} do
      Enum.each(0..99, fn _turn ->
        assert_receive {:tcp, ^p1, commands_request}

        assert %{"commands_request" => %{"request_id" => request_id}} =
                 Jason.decode!(commands_request)

        :ok = :gen_tcp.send(p1, empty_commands_msg(request_id))

        assert_receive {:tcp, ^p2, commands_request}

        assert %{"commands_request" => %{"request_id" => request_id}} =
                 Jason.decode!(commands_request)

        :ok = :gen_tcp.send(p2, empty_commands_msg(request_id))
      end)

      assert_receive {:tcp, ^p1, game_over}
      assert_receive {:tcp, ^p2, ^game_over}

      assert %{"info" => "game_over", "result" => %{"winner" => _, "game_id" => ^game_id}} =
               Jason.decode!(game_over)
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
