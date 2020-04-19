defmodule BattleBox.Connection.Message do
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
    game_info = Map.take(game_info, [:settings, :game_id, :player])
    encode(%{"game_info" => game_info, "request_type" => "game_request"})
  end

  def encode_error(error_msg, additional \\ %{}) do
    error = Map.merge(%{error: error_msg}, additional)
    encode(error)
  end

  defmacro bot_token_auth(token, lobby_name) do
    quote do
      %{"token" => unquote(token), "lobby" => unquote(lobby_name)}
    end
  end

  defmacro start_match_making do
    quote do
      %{"action" => "start_match_making"}
    end
  end

  defmacro accept_game(game_id) do
    quote do
      %{"action" => "accept_game", "game_id" => unquote(game_id)}
    end
  end

  defmacro reject_game(game_id) do
    quote do
      %{"action" => "reject_game", "game_id" => unquote(game_id)}
    end
  end

  defmacro sent_commands(request_id, commands) do
    quote do
      %{
        "action" => "send_commands",
        "request_id" => unquote(request_id),
        "commands" => unquote(commands)
      }
    end
  end

  def encode(msg), do: Jason.encode!(msg)
end
