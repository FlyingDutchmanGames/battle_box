defmodule BattleBox.TcpConnectionServer.ConnectionHandler do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter], restart: :temporary
  alias BattleBox.{GameEngine, PlayerServer}
  @behaviour :ranch_protocol
  @invalid_json_msg Jason.encode!(%{error: "invalid_json"})

  def start_link(ref, _socket, transport, data) do
    data =
      Map.merge(data, %{
        connection_id: Ecto.UUID.generate(),
        ranch_ref: ref,
        ranch_transport: transport
      })

    GenStateMachine.start_link(__MODULE__, data)
  end

  def init(data) do
    {:ok, :unauthed, data, {:next_event, :internal, :initialize}}
  end

  def handle_event(:internal, :initialize, :unauthed, data) do
    Registry.register(data.names.connection_registry, data.connection_id, %{connection_type: :tcp})

    {:ok, socket} = :ranch.handshake(data.ranch_ref)
    :ok = data.ranch_transport.setopts(socket, active: :once)
    :ok = data.ranch_transport.send(socket, inital_msg(data.connection_id))

    data = Map.merge(data, %{socket: socket})

    {:keep_state, data}
  end

  def handle_event(:info, {:tcp, socket, msg}, :unauthed, %{socket: socket} = data) do
    :ok = data.ranch_transport.setopts(socket, active: :once)

    case Jason.decode(msg) do
      {:ok, %{"bot_id" => bot_id, "bot_token" => _}} ->
        # TODO: Validate auth here

        {:ok, player_server} =
          GameEngine.start_player(data.names.game_engine, %{
            connection: self(),
            connection_id: data.connection_id,
            player_id: bot_id
          })

        Process.monitor(player_server)

        data =
          Map.merge(data, %{
            player_id: bot_id,
            player_server: player_server
          })

        :ok = data.ranch_transport.send(socket, idle_status_msg(bot_id, nil))

        {:next_state, :idle, data}

      {:error, _} ->
        :ok = data.ranch_transport.send(socket, @invalid_json_msg)
        :keep_state_and_data
    end
  end

  def handle_event(:info, {:tcp, socket, msg}, :idle, %{socket: socket} = data) do
    :ok = data.ranch_transport.setopts(socket, active: :once)

    case Jason.decode(msg) do
      {:ok, %{"action" => "join_lobby", "lobby_name" => lobby_name}} ->
        :ok = PlayerServer.join_lobby(data.player_server, lobby_name)
        data = Map.put(data, :lobby_name, lobby_name)
        :ok = data.ranch_transport.send(socket, idle_status_msg(data.player_id, lobby_name))
        {:keep_state, data}

      {:error, _} ->
        :ok = data.ranch_transport.send(socket, @invalid_json_msg)
        :keep_state_and_data
    end
  end

  def handle_event(:enter, _old_state, _state, _data), do: :keep_state_and_data

  defp idle_status_msg(bot_id, lobby_name) do
    %{
      bot_id: bot_id,
      lobby_name: lobby_name
    }
    |> Jason.encode!()
  end

  defp inital_msg(connection_id) do
    %{
      connection_id: connection_id,
      message: "Welcome to BattleBox!"
    }
    |> Jason.encode!()
  end

  # def handle_info({:tcp, socket, request}, transport) do
  #   IO.inspect("TCP")
  #   IO.inspect(socket, label: "SOCKET")
  #   IO.inspect(request, label: "request")
  #   IO.inspect(transport, label: "transport")
  #   transport.send(socket, "HI")
  #   :ok = transport.setopts(socket, active: :once)
  #   {:noreply, transport}
  # end

  # def handle_info({:tcp_closed, _socket}, state) do
  #   IO.inspect("TCP CLOSED")
  #   {:stop, :normal, state}
  # end

  # def handle_info({:tcp_error, _socket, reason}, state) do
  #   IO.inspect("TCP ERROR")
  #   IO.inspect(reason, label: "REASON")
  #   {:stop, reason, state}
  # end
end
