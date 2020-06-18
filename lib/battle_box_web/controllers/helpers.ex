defmodule BattleBoxWeb.Controllers.Helpers do
  import Phoenix.Controller
  import Plug.Conn
  alias BattleBoxWeb.PageView
  alias BattleBox.{User, Bot, Arena}

  def render404(conn, message) do
    message =
      case message do
        {Bot, name} -> "Bot (#{name}) Not Found"
        {Bot, name, username} -> "Bot (#{name}) for User (#{username}) Not Found"
        {Arena, name} -> "Arena (#{name}) Not Found"
        {Arena, name, username} -> "Arena (#{name}) for User (#{username}) Not Found"
        {User, username} -> "User (#{username}) Not Found"
        message when is_binary(message) -> message
      end

    conn
    |> put_status(404)
    |> put_view(PageView)
    |> render("not_found.html", message: message)
  end
end
