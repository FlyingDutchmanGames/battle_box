defmodule BattleBox.TcpConnectionServer.ConnectionHandler do
  use GenStateMachine, callback_mode: [:handle_event_function], restart: :temporary
  import BattleBox.Connection.Message
  alias BattleBox.Connection.Logic
  @behaviour :ranch_protocol

  def start_link(ref, _socket, transport, data) do
    data = Map.put_new(data, :connection_id, Ecto.UUID.generate())
    data = Map.merge(data, %{ranch_ref: ref, transport: transport})

    GenStateMachine.start_link(__MODULE__, data,
      name:
        {:via, Registry,
         {data.names.connection_registry, data.connection_id, %{started_at: DateTime.utc_now()}}}
    )
  end

  def init(data) do
    data = Logic.init(data)
    {:ok, :running, data, {:next_event, :internal, :initialize}}
  end

  def handle_event(:internal, :initialize, _, data) do
    {:ok, socket} = :ranch.handshake(data.ranch_ref)
    data = Map.put(data, :socket, socket)
    :ok = data.transport.setopts(socket, active: :once, packet: 2, keepalive: true, recbuf: 65536)
    {:keep_state, data}
  end

  def handle_event(:info, {:tcp_closed, _socket}, _state, _data), do: {:stop, :normal}
  def handle_event(:info, {:tcp_error, _socket, _reason}, _state, _data), do: {:stop, :normal}

  def handle_event(:info, {:tcp, socket, bytes}, _state, data) do
    :ok = data.transport.setopts(socket, active: :once)

    case Jason.decode(bytes) do
      {:ok, msg} ->
        {:keep_state_and_data, {:next_event, :internal, msg}}

      {:error, %Jason.DecodeError{}} ->
        :ok = send_to_socket(data, encode_error("invalid_json"))
        :keep_state_and_data
    end
  end

  def handle_event(_, msg, _state, data) do
    {data, actions, continue?} = Logic.handle_message(msg, data)

    Enum.each(actions, fn
      {:send, msg} -> send_to_socket(data, msg)
      {:monitor, pid} -> Process.monitor(pid)
    end)

    case continue? do
      :continue -> {:keep_state, data}
      :stop -> {:stop, :normal}
    end
  end

  defp send_to_socket(data, msg) do
    :ok = data.transport.send(data.socket, msg)
  end
end
