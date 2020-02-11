defmodule BattleBox.TcpConnectionServer.ConnectionHandlerTest do
  use BattleBox.DataCase
  alias BattleBox.{GameEngine, TcpConnectionServer, Lobby}
  alias BattleBox.Games.RobotGame.Game

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
        Jason.encode!(%{
          "bot_id" => "1234",
          "bot_token" => "5678",
          "lobby_name" => context.lobby.name
        })
    }
  end

  test "you can connect", context do
    {:ok, socket} = :gen_tcp.connect(@ip, context.port, [:binary, active: true])
    assert_receive {:tcp, ^socket, msg}
    assert %{"connection_id" => connection_id} = Jason.decode!(msg)
  end

  describe "joining a lobby as a bot" do
    setup context do
      {:ok, socket} = :gen_tcp.connect(@ip, context.port, [:binary, active: true])
      assert_receive {:tcp, ^socket, connection_msg}
      %{"connection_id" => connection_id} = Jason.decode!(connection_msg)
      %{socket: socket, connection_id: connection_id}
    end

    test "you can join as a bot", %{socket: socket, lobby: %{name: lobby_name}} do
      bot_connect_req =
        Jason.encode!(%{
          "bot_id" => "1234",
          "bot_token" => "5678",
          "lobby_name" => lobby_name
        })

      :ok = :gen_tcp.send(socket, bot_connect_req)
      assert_receive {:tcp, ^socket, msg}

      assert %{"bot_id" => "1234", "lobby_name" => ^lobby_name, "status" => "idle"} =
               Jason.decode!(msg)
    end

    test "trying to join a lobby that doesn't exist is an error", %{socket: socket} = context do
      bot_connect_req =
        Jason.encode!(%{
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

      assert_receive {:tcp, ^socket, "{\"error\":\"bot_instance_failure\"}"}
      assert_receive {:DOWN, _, _, ^connection_pid, :normal}
    end

    test "if you try to join as a bot that doesn't exist it fails" do
      # TODO:// BOT AUTH
    end
  end

  describe "matching_making" do
    setup context do
      for player <- [:player_1, :player_2] do
        {:ok, socket} = :gen_tcp.connect(@ip, context.port, [:binary, active: true])
        assert_receive {:tcp, ^socket, _connection_msg}

        join_request =
          Jason.encode!(%{
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

    test "you can join a matchmaking queue", %{player_1: %{socket: socket}} do
      start_matchmaking_msg = Jason.encode!(%{"action" => "start_match_making"})
      :ok = :gen_tcp.send(socket, start_matchmaking_msg)
      assert_receive {:tcp, ^socket, resp}

      %{"status" => "match_making"} = Jason.decode!(resp)
    end
  end
end
