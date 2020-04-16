defmodule BattleBox.TcpConnectionServer.Message do
  def game_over(result) do
    encode(%{"info" => "game_over", "result" => result})
  end

  def commands_request(request) do
    encode(%{"request_type" => "commands_request", "commands_request" => request})
  end

  def game_cancelled(game_id) do
    encode(%{info: "game_cancelled", game_id: game_id})
  end

  def status_msg(data, status) do
    encode(%{
      status: status,
      connection_id: data.connection_id,
      user_id: data.user_id,
      bot_server_id: data.bot_server_id
    })
  end

  def game_request(game_info) do
    game_info = Map.take(game_info, [:acceptance_time, :game_id, :player])
    encode(%{"game_info" => game_info, "request_type" => "game_request"})
  end

  def encode_error(error_msg, additional \\ %{}) do
    error = Map.merge(%{error: error_msg}, additional)
    encode(error)
  end

  def encode(msg), do: Jason.encode!(msg)
end
