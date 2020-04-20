defmodule BattleBox.TcpConnectionServer.ConnectionHandler do
  use GenServer, restart: :temporary
  import BattleBox.Connection.Message
  alias BattleBox.Connection.Logic
  @behaviour :ranch_protocol

  def start_link(ref, _socket, transport, data) do
    data = Map.put_new(data, :connection_id, Ecto.UUID.generate())
    data = Map.merge(data, %{ranch_ref: ref, transport: transport})

    GenServer.start_link(__MODULE__, data,
      name:
        {:via, Registry,
         {data.names.connection_registry, data.connection_id, %{started_at: DateTime.utc_now()}}}
    )
  end

  def init(data) do
    data = Logic.init(data)
    {:ok, data, {:continue, :initialize_tcp_connection}}
  end

  def handle_continue(:initialize_tcp_connection, data) do
    {:ok, socket} = :ranch.handshake(data.ranch_ref)
    data = Map.put(data, :socket, socket)
    :ok = data.transport.setopts(socket, active: :once, packet: 2, keepalive: true, recbuf: 65536)
    {:noreply, data}
  end

  def handle_info({:tcp_closed, _socket}, data), do: {:stop, :normal, data}
  def handle_info({:tcp_error, _socket, _reason}, data), do: {:stop, :normal, data}

  def handle_info({:tcp, socket, bytes}, data) do
    :ok = data.transport.setopts(socket, active: :once)

    case Jason.decode(bytes) do
      {:ok, msg} ->
        handle_msg({:client, msg}, data)

      {:error, %Jason.DecodeError{}} ->
        :ok = data.transport.send(data.socket, encode_error("invalid_json"))
        {:noreply, data}
    end
  end

  def handle_info(msg, data), do: handle_msg({:system, msg}, data)

  defp handle_msg(msg, data) do
    {data, actions, continue?} = Logic.handle_message(msg, data)

    Enum.each(actions, fn
      {:send, msg} -> data.transport.send(data.socket, msg)
      {:monitor, pid} -> Process.monitor(pid)
    end)

    case continue? do
      :continue -> {:noreply, data}
      :stop -> {:stop, :normal, data}
    end
  end
end
