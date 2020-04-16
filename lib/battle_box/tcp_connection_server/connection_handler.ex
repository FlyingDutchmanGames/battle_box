defmodule BattleBox.TcpConnectionServer.ConnectionHandler do
  use GenStateMachine, callback_mode: [:handle_event_function], restart: :temporary
  alias BattleBox.{GameEngine, GameEngine.BotServer}
  import BattleBox.TcpConnectionServer.Message
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
    {:ok, :unauthed, data, {:next_event, :internal, :initialize}}
  end

  def handle_event(:internal, :initialize, :unauthed, data) do
    {:ok, socket} = :ranch.handshake(data.ranch_ref)
    data = Map.put(data, :socket, socket)
    :ok = data.transport.setopts(socket, active: :once, packet: 2, recbuf: 65536)
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

  def handle_event(:internal, %{"token" => token, "lobby" => lobby_name}, :unauthed, data) do
    case GameEngine.start_bot(data.names.game_engine, %{
           token: token,
           lobby_name: lobby_name,
           connection: self()
         }) do
      {:ok, bot_server, %{user_id: _, bot_server_id: _} = bot_server_info} ->
        Process.monitor(bot_server)
        data = data |> Map.put(:bot_server, bot_server) |> Map.merge(bot_server_info)
        :ok = send_to_socket(data, status_msg(data, :idle))
        {:next_state, :idle, data}

      {:error, error} when error in [:invalid_token, :lobby_not_found, :banned] ->
        :ok = send_to_socket(data, encode_error(error))
        :keep_state_and_data
    end
  end

  def handle_event(:internal, %{"action" => "start_match_making"}, :idle, data) do
    :ok = BotServer.match_make(data.bot_server)
    :ok = send_to_socket(data, status_msg(data, :match_making))
    {:next_state, :match_making, data}
  end

  def handle_event(:info, {:game_request, game_info}, :match_making, data) do
    :ok = send_to_socket(data, game_request(game_info))
    data = Map.put(data, :game_info, game_info)
    {:next_state, :game_acceptance, data}
  end

  def handle_event(
        :internal,
        %{"action" => action, "game_id" => id},
        :game_acceptance,
        %{game_info: %{game_id: id}} = data
      )
      when action in ["accept_game", "reject_game"] do
    case action do
      "accept_game" -> :ok = BotServer.accept_game(data.bot_server, id)
      "reject_game" -> :ok = BotServer.reject_game(data.bot_server, id)
    end

    {:next_state, :playing, data}
  end

  def handle_event(:info, {:commands_request, request}, :playing, data) do
    :ok = send_to_socket(data, commands_request(request))
    {:keep_state, data}
  end

  def handle_event(
        :internal,
        %{"action" => "send_commands", "request_id" => request_id, "commands" => commands},
        :playing,
        data
      ) do
    case BotServer.submit_commands(data.bot_server, request_id, commands) do
      :ok ->
        {:keep_state, data}

      {:error, :invalid_commands_submission} ->
        error = encode_error("invalid_commands_submission", %{"request_id" => request_id})
        :ok = send_to_socket(data, error)
        {:keep_state, data}
    end
  end

  def handle_event(:info, {:game_over, %{game_id: game_id} = result}, _, data) do
    :ok = send_to_socket(data, game_over(result))
    {:ok, data} = teardown_game(data, game_id)
    {:next_state, :idle, data}
  end

  def handle_event(:info, {:game_cancelled, id}, _state, %{game_info: %{game_id: id}} = data) do
    :ok = send_to_socket(data, game_cancelled(id))
    {:ok, data} = teardown_game(data, id)
    {:next_state, :idle, data}
  end

  def handle_event(:info, {:DOWN, _, _, pid, _}, _state, %{bot_server: pid} = data) do
    :ok = send_to_socket(data, encode_error("bot_instance_failure"))
    :ok = data.transport.close(data.socket)
    {:stop, :normal}
  end

  def handle_event(:internal, _msg, _state, data) do
    :ok = send_to_socket(data, encode_error("invalid_msg_sent"))
    :keep_state_and_data
  end

  defp teardown_game(data, _game_id) do
    {:ok, Map.drop(data, [:game_info])}
  end

  defp send_to_socket(data, msg) do
    :ok = data.transport.send(data.socket, msg)
  end
end
