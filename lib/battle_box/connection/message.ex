defmodule BattleBox.Connection.Message do
  alias BattleBoxWeb.Endpoint
  alias BattleBoxWeb.Router.Helpers, as: Routes

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
      bot_server_id: data.bot_server_id,
      watch: watch_info(data)
    })
  end

  def game_request(game_info) do
    game_info = Map.take(game_info, [:game_type, :settings, :game_id, :player])
    encode(%{"game_info" => game_info, "request_type" => "game_request"})
  end

  def encode_error(error_msg, additional \\ %{}) do
    error = Map.merge(%{error: error_msg}, additional)
    encode(error)
  end

  defmacro bot_token_auth(token, bot_name) do
    quote do
      %{"token" => unquote(token), "bot" => unquote(bot_name)}
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

  defp watch_info(data) do
    case data do
      %{bot: %{user: %{username: username}, name: bot_name}} ->
        %{
          user: Routes.user_follow_url(Endpoint, :follow, username),
          bot: Routes.user_bot_follow_url(Endpoint, :follow, username, bot_name)
        }

      _ ->
        %{}
    end
  end
end
