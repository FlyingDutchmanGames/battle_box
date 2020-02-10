defmodule BattleBox.TcpConnections.ConnectionHandler do
  @behaviour :ranch_protocol

  def start_link(ref, _socket, transport, _opts) do
    GenServer.start_link(__MODULE__, {ref, transport})
  end

  def init({ref, transport}) do
    {:ok, {ref, transport}, {:continue, :handshake}}
  end

  def handle_continue(:handshake, {ref, transport}) do
    IO.inspect("HANDSHAKE")
    IO.inspect(ref, label: "REF")
    IO.inspect(transport, label: "TRANSPORT")

    {:ok, socket} = :ranch.handshake(ref)
    IO.inspect(socket, label: "SOCKET")
    :ok = transport.setopts(socket, active: :once)

    {:noreply, transport}
  end

  def handle_info({:tcp, socket, request}, transport) do
    IO.inspect("TCP")
    IO.inspect(socket, label: "SOCKET")
    IO.inspect(request, label: "request")
    IO.inspect(transport, label: "transport")
    transport.send(socket, "HI")
    :ok = transport.setopts(socket, active: :once)
    {:noreply, transport}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    IO.inspect("TCP CLOSED")
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    IO.inspect("TCP ERROR")
    IO.inspect(reason, label: "REASON")
    {:stop, reason, state}
  end
end
