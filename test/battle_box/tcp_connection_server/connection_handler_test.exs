defmodule BattleBox.TcpConnectionServer.ConnectionHandlerTest do
  use BattleBox.DataCase
  alias BattleBox.{GameEngine, TcpConnectionServer, Lobby}
  alias BattleBox.Games.RobotGame.Game
  import BattleBox.TcpConnectionServer.Message

  @ip {127, 0, 0, 1}

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup %{game_engine: game_engine, test: name} do
    # Get an open port 🤷
    {:ok, socket} = :ranch_tcp.listen(ip: @ip, port: 0)
    {:ok, port} = :inet.port(socket)
    true = :erlang.port_close(socket)

    {:ok, _} =
      Supervisor.start_link(
        [{TcpConnectionServer, port: port, game_engine: game_engine, name: :"#{name}1"}],
        strategy: :one_for_one
      )

    %{port: port}
  end

  setup do
    changeset = Lobby.changeset(%Lobby{}, %{name: "LOBBY NAME", game_type: Game})
    {:ok, lobby} = Repo.insert(changeset)
    %{lobby: lobby}
  end

  setup context do
    %{
      connection_request:
        encode(%{
          "bot_id" => "1234",
          "bot_token" => "5678",
          "lobby_name" => context.lobby.name
        }),
      start_matchmaking_request: encode(%{"action" => "start_match_making"})
    }
  end

  test "you can connect", context do
    {:ok, socket} = connect(context.port)
    assert_receive {:tcp, ^socket, msg}
    assert %{"connection_id" => connection_id} = Jason.decode!(msg)
  end

  test "closing the tcp connection causes the connection process to die", context do
    {:ok, socket} = connect(context.port)
    assert_receive {:tcp, ^socket, msg}
    assert %{"connection_id" => connection_id} = Jason.decode!(msg)
    %{pid: pid} = GameEngine.get_connection(context.game_engine, connection_id)
    ref = Process.monitor(pid)
    :ok = :gen_tcp.close(socket)
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
  end

  describe "joining a lobby as a bot" do
    setup context do
      {:ok, socket} = connect(context.port)
      assert_receive {:tcp, ^socket, connection_msg}
      %{"connection_id" => connection_id} = Jason.decode!(connection_msg)
      %{socket: socket, connection_id: connection_id}
    end

    test "you can join as a bot", %{socket: socket, lobby: %{name: lobby_name}} do
      bot_connect_req =
        encode(%{
          "bot_id" => "1234",
          "bot_token" => "5678",
          "lobby_name" => lobby_name
        })

      :ok = :gen_tcp.send(socket, bot_connect_req)
      assert_receive {:tcp, ^socket, msg}

      assert %{"bot_id" => "1234", "lobby_name" => ^lobby_name, "status" => "idle"} =
               Jason.decode!(msg)
    end

    test "trying to join a lobby that doesn't exist is an error", %{socket: socket} do
      bot_connect_req =
        encode(%{
          "bot_id" => "1234",
          "bot_token" => "5678",
          "lobby_name" => "FAKE"
        })

      :ok = :gen_tcp.send(socket, bot_connect_req)
      assert_receive {:tcp, ^socket, msg}
      assert %{"error" => "lobby_not_found"} = Jason.decode!(msg)
    end

    test "you get notified if the player server dies and the connection closes",
         %{socket: socket} = context do
      :ok = :gen_tcp.send(socket, context.connection_request)

      assert_receive {:tcp, ^socket, msg}
      [player_pid] = Registry.select(context.player_registry, [{{:_, :"$1", :_}, [], [:"$1"]}])
      [{connection_pid, _}] = Registry.lookup(context.connection_registry, context.connection_id)
      Process.monitor(connection_pid)
      Process.exit(player_pid, :kill)

      assert_receive {:tcp, ^socket, msg}
      assert %{"error" => "bot_instance_failure"} = Jason.decode!(msg)
      assert_receive {:DOWN, _, _, ^connection_pid, :normal}
    end

    test "if you try to join as a bot that doesn't exist it fails" do
      # TODO:// BOT AUTH
    end
  end

  describe "matching_making" do
    setup context do
      for player <- [:p1, :p2] do
        {:ok, socket} = connect(context.port)
        assert_receive {:tcp, ^socket, _connection_msg}

        join_request =
          encode(%{
            "bot_id" => "#{player}1234",
            "bot_token" => "5678",
            "lobby_name" => context.lobby.name
          })

        :ok = :gen_tcp.send(socket, join_request)
        assert_receive {:tcp, ^socket, _bot_connect_msg}

        {player, %{socket: socket}}
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
                 "acceptance_time" => 2000,
                 "game_id" => <<_::288>>,
                 "player" => "player_" <> _
               },
               "request_type" => "game_request"
             } = Jason.decode!(game_request)
    end
  end

  describe "game acceptance" do
    setup context do
      for player <- [:p1, :p2] do
        {:ok, socket} = connect(context.port)
        assert_receive {:tcp, ^socket, connection_msg}
        %{"connection_id" => connection_id} = Jason.decode!(connection_msg)
        %{pid: pid} = GameEngine.get_connection(context.game_engine, connection_id)

        join_request =
          encode(%{
            "bot_id" => "#{player}1234",
            "bot_token" => "5678",
            "lobby_name" => context.lobby.name
          })

        :ok = :gen_tcp.send(socket, join_request)
        assert_receive {:tcp, ^socket, _bot_connect_msg}

        :ok = :gen_tcp.send(socket, context.start_matchmaking_request)
        assert_receive {:tcp, ^socket, msg}

        {player, %{socket: socket, connection_id: connection_id, connection_pid: pid}}
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
  end

  defp connect(port) do
    :gen_tcp.connect(@ip, port, [:binary, active: true, packet: :line])
  end
end
