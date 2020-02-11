defmodule BattleBox.TcpConnectionServer.ConnectionHandler do
  use GenStateMachine, callback_mode: [:handle_event_function], restart: :temporary
  alias BattleBox.{GameEngine, PlayerServer}
  @behaviour :ranch_protocol

  @invalid_json_msg Jason.encode!(%{error: "invalid_json"})
  @invalid_msg_sent Jason.encode!(%{error: "invalid_msg_sent"})
  @lobby_not_found_msg Jason.encode!(%{error: "lobby_not_found"})
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

    with {1, {:ok, %{"bot_id" => bot_id, "bot_token" => _, "lobby_name" => lobby_name}}} <-
           {1, Jason.decode(msg)},
         {2, {:ok, player_server}} <-
           {2,
            GameEngine.start_player(data.names.game_engine, %{
              connection: self(),
              player_id: bot_id,
              lobby_name: lobby_name
            })} do
      Process.monitor(player_server)

      data =
        Map.merge(data, %{
          player_id: bot_id,
          player_server: player_server,
          lobby_name: lobby_name,
          status: :idle
        })

      :ok = data.transport.send(socket, status_msg(data))
      {:next_state, :idle, data}
    else
      {1, {:ok, _invalid_params}} ->
        :ok = data.transport.send(socket, @invalid_msg_sent)
        :keep_state_and_data

      {1, {:error, %Jason.DecodeError{}}} ->
        :ok = data.transport.send(socket, @invalid_json_msg)
        :keep_state_and_data

      {2, {:error, :lobby_not_found}} ->
        :ok = data.transport.send(socket, @lobby_not_found_msg)
        :keep_state_and_data
    end
  end

  def handle_event(:info, {:tcp, socket, msg}, :idle, %{socket: socket} = data) do
    :ok = data.transport.setopts(socket, active: :once)

    case Jason.decode(msg) do
      {:ok, %{"action" => "start_match_making"}} ->
        :ok = PlayerServer.match_make(data.player_server)
        data = Map.put(data, :status, :match_making)
        :ok = data.transport.send(socket, status_msg(data))
        {:next_state, :match_making, data}

      {:ok, _invalid_params} ->
        :ok = data.transport.send(socket, @invalid_msg_sent)
        :keep_state_and_data

      {:error, %Jason.DecodeError{}} ->
        :ok = data.transport.send(socket, @invalid_json_msg)
        :keep_state_and_data
    end
  end

  def handle_event(:info, {:game_request, game_info}, :match_making, data) do
    :ok = data.transport.send(data.socket, game_request(game_info))
    data = Map.put(data, :game_request, game_info)
    {:keep_state, data}
  end

  def handle_event(:info, {:DOWN, _, _, pid, _}, _state, %{player_server: pid} = data) do
    :ok = data.transport.send(data.socket, @bot_instance_failure)
    :ok = data.transport.close(data.socket)
    {:stop, :normal}
  end

  def handle_event(:info, {:tcp_closed, _socket}, _state, _data), do: {:stop, :normal}
  def handle_event(:info, {:tcp_error, _socket, _reason}, _state, _data), do: {:stop, :normal}

  defp game_request(game_info) do
    game_info = Map.take(game_info, [:acceptance_time, :game_id, :player])
    Jason.encode!(%{request_type: "game_request", game_info: game_info})
  end

  defp status_msg(data) do
    Jason.encode!(%{
      bot_id: data.player_id,
      lobby_name: data.lobby_name,
      status: data.status
    })
  end

  defp initial_msg(connection_id), do: Jason.encode!(%{connection_id: connection_id})
end
