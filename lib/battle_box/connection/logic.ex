defmodule BattleBox.Connection.Logic do
  alias BattleBox.{GameEngine, GameEngine.BotServer}
  import BattleBox.Connection.Message

  def init(data) do
    Map.put(data, :state, :unauthed)
  end

  def handle_message(msg, data) do
    case msg do
      {:system, msg} -> handle_system(msg, data)
      {:client, msg} -> handle_client(msg, data)
    end
  end

  def handle_system({:game_request, game_info}, %{state: :match_making} = data) do
    data = Map.put(data, :state, :game_acceptance)
    {data, [{:send, game_request(game_info)}], :continue}
  end

  def handle_system({:commands_request, request}, %{state: :playing} = data) do
    {data, [{:send, commands_request(request)}], :continue}
  end

  def handle_system({:game_over, result}, data) do
    data = Map.put(data, :state, :idle)
    {data, [{:send, game_over(result)}], :continue}
  end

  def handle_system({:game_cancelled, id}, data) do
    data = Map.put(data, :state, :idle)
    {data, [{:send, game_cancelled(id)}], :continue}
  end

  def handle_system({:DOWN, _, _, pid, _}, %{bot_server: pid} = data) do
    {data, [{:send, encode_error("bot_instance_failure")}], :stop}
  end

  def handle_client(bot_token_auth(token, bot_name, lobby_name), %{state: :unauthed} = data) do
    case GameEngine.start_bot(data.names.game_engine, %{
           token: token,
           lobby_name: lobby_name,
           bot_name: bot_name,
           connection: self()
         }) do
      {:ok, bot_server, %{user_id: _, bot_server_id: _} = bot_server_info} ->
        data =
          data
          |> Map.put(:bot_server, bot_server)
          |> Map.put(:state, :idle)
          |> Map.merge(bot_server_info)

        {data, [{:monitor, bot_server}, {:send, status_msg(data, :idle)}], :continue}

      {:error, error} when error in [:invalid_token, :lobby_not_found, :banned] ->
        {data, [{:send, encode_error(error)}], :continue}
    end
  end

  def handle_client(start_match_making(), %{state: :idle} = data) do
    :ok = BotServer.match_make(data.bot_server)
    data = Map.put(data, :state, :match_making)
    {data, [{:send, status_msg(data, :match_making)}], :continue}
  end

  def handle_client(accept_game(id), %{state: :game_acceptance} = data) do
    :ok = BotServer.accept_game(data.bot_server, id)
    data = Map.put(data, :state, :playing)
    {data, [], :continue}
  end

  def handle_client(reject_game(id), %{state: :game_acceptance} = data) do
    :ok = BotServer.reject_game(data.bot_server, id)
    data = Map.put(data, :state, :playing)
    {data, [], :continue}
  end

  def handle_client(sent_commands(request_id, commands), %{state: :playing} = data) do
    case BotServer.submit_commands(data.bot_server, request_id, commands) do
      :ok ->
        {data, [], :continue}

      {:error, :invalid_commands_submission} ->
        error = encode_error("invalid_commands_submission", %{"request_id" => request_id})
        {data, [{:send, error}], :continue}
    end
  end

  def handle_client(_msg, data) do
    {data, [{:send, encode_error("invalid_msg_sent")}], :continue}
  end
end
