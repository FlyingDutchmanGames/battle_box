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
        [
          {TcpConnectionServer,
           port: port, game_engine: game_engine, name: :"#{name}-connection-server"}
        ],
        strategy: :one_for_one
      )

    %{port: port}
  end

  setup do
    changeset = Lobby.changeset(%Lobby{}, %{name: "LOBBY NAME", game_type: Game})
    {:ok, lobby} = Repo.insert(changeset)
    %{lobby: lobby}
  end

  test "you can connect", context do
    {:ok, socket} = :gen_tcp.connect(@ip, context.port, [:binary, active: true])

    assert_receive {:tcp, ^socket, msg}

    assert %{
             "connection_id" => connection_id,
             "message" => "Welcome to BattleBox!"
           } = Jason.decode!(msg)
  end

  describe "joining as a bot" do
    setup context do
      {:ok, socket} = :gen_tcp.connect(@ip, context.port, [:binary, active: true])
      assert_receive {:tcp, ^socket, connection_msg}
      %{"connection_id" => _} = Jason.decode!(connection_msg)
      %{socket: socket}
    end

    test "you can join as a bot", %{socket: socket} do
      :ok = :gen_tcp.send(socket, Jason.encode!(%{"bot_id" => "1234", "bot_token" => "5678"}))
      assert_receive {:tcp, ^socket, msg}
      assert %{"bot_id" => "1234", "lobby_name" => nil} = Jason.decode!(msg)
    end

    test "if you try to join as a bot that doesn't exist it fails" do
      # TODO:// BOT AUTH
    end
  end

  describe "joining a lobby" do
    setup context do
      {:ok, socket} = :gen_tcp.connect(@ip, context.port, [:binary, active: true])
      assert_receive {:tcp, ^socket, connection_msg}
      %{"connection_id" => _} = Jason.decode!(connection_msg)
      :ok = :gen_tcp.send(socket, Jason.encode!(%{"bot_id" => "1234", "bot_token" => "5678"}))
      assert_receive {:tcp, ^socket, bot_connect_msg}
      assert %{"bot_id" => "1234", "lobby_name" => nil} = Jason.decode!(bot_connect_msg)
      %{socket: socket}
    end

    test "you can join a lobby", %{socket: socket, lobby: %{name: lobby_name}} do
      :ok =
        :gen_tcp.send(
          socket,
          Jason.encode!(%{
            "action" => "join_lobby",
            "lobby_name" => lobby_name
          })
        )

      assert_receive {:tcp, ^socket, msg}

      assert %{
               "bot_id" => "1234",
               "lobby_name" => ^lobby_name
             } = Jason.decode!(msg)
    end
  end

  # assert [{connection_pid, %{connection_type: :tcp}}] = Registry.lookup(context.connection_registry, connection_id)
  # Process.monitor(connection_pid)
end
