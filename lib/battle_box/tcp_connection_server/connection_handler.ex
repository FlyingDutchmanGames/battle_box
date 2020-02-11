defmodule BattleBox.TcpConnectionServer.ConnectionHandler do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter], restart: :temporary
  alias BattleBox.{GameEngine, PlayerServer}
  @behaviour :ranch_protocol

  @invalid_json_msg Jason.encode!(%{error: "invalid_json"})
  @lobby_not_found Jason.encode!(%{error: "lobby_not_found"})
  @bot_instance_failure Jason.encode!(%{error: "bot_instance_failure"})

  def start_link(ref, _socket, transport, data) do
    data =
      Map.merge(data, %{
        connection_id: Ecto.UUID.generate(),
        ranch_ref: ref,
        transport: transport
      })

    GenStateMachine.start_link(__MODULE__, data)
  end

  def init(data) do
    {:ok, :unauthed, data, {:next_event, :internal, :initialize}}
  end

  def handle_event(:internal, :initialize, :unauthed, data) do
    Registry.register(data.names.connection_registry, data.connection_id, %{connection_type: :tcp})

    {:ok, socket} = :ranch.handshake(data.ranch_ref)
    :ok = data.transport.setopts(socket, active: :once)
    :ok = data.transport.send(socket, initial_msg(data.connection_id))

    data = Map.put(data, :socket, socket)

    {:keep_state, data}
  end

  def handle_event(:info, {:tcp, socket, msg}, :unauthed, %{socket: socket} = data) do
    :ok = data.transport.setopts(socket, active: :once)

    case Jason.decode(msg) do
      {:ok, %{"bot_id" => bot_id, "bot_token" => _}} ->
        # TODO: Validate auth here

        {:ok, player_server} =
          GameEngine.start_player(data.names.game_engine, %{
            connection: self(),
            player_id: bot_id
          })

        Process.monitor(player_server)
        data = Map.merge(data, %{player_id: bot_id, player_server: player_server})
        :ok = data.transport.send(socket, status_msg(data))
        {:next_state, :idle, data}

      {:error, %Jason.DecodeError{}} ->
        :ok = data.transport.send(socket, @invalid_json_msg)
        :keep_state_and_data
    end
  end

  def handle_event(:info, {:tcp, socket, msg}, :idle, %{socket: socket} = data) do
    :ok = data.transport.setopts(socket, active: :once)

    case Jason.decode(msg) do
      {:ok, %{"action" => "join_lobby", "lobby_name" => lobby_name}} ->
        case PlayerServer.join_lobby(data.player_server, lobby_name) do
          :ok ->
            data = Map.put(data, :lobby_name, lobby_name)
            :ok = data.transport.send(socket, status_msg(data))
            {:keep_state, data}

          {:error, :lobby_not_found} ->
            :ok = data.transport.send(socket, @lobby_not_found)
            {:keep_state, data}
        end

      {:error, %Jason.DecodeError{}} ->
        :ok = data.transport.send(socket, @invalid_json_msg)
        :keep_state_and_data
    end
  end

  def handle_event(:info, {:DOWN, _, _, pid, _}, _state, %{player_server: pid} = data) do
    :ok = data.transport.send(data.socket, @bot_instance_failure)
    :ok = data.transport.close(data.socket)
    {:stop, :normal}
  end

  def handle_event(:info, {:tcp_closed, _socket}, _state, _data), do: {:stop, :normal}
  def handle_event(:info, {:tcp_error, _socket, _reason}, _state, _data), do: {:stop, :normal}

  def handle_event(:enter, _old_state, _state, _data), do: :keep_state_and_data

  defp status_msg(data) do
    Jason.encode!(%{
      bot_id: data[:player_id],
      lobby_name: data[:lobby_name]
    })
  end

  defp initial_msg(connection_id), do: Jason.encode!(%{connection_id: connection_id})
end
