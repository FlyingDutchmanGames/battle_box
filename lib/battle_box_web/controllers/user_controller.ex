defmodule BattleBoxWeb.UserController do
  use BattleBoxWeb, :controller
  alias BattleBoxWeb.PageView
  alias BattleBox.User

  def show(conn, %{"id" => id}) do
    case User.get_by_identifier(id) do
      %User{} = user ->
        render(conn, "show.html", fetched_user: user)

      nil ->
        conn
        |> put_status(404)
        |> put_view(PageView)
        |> render("not_found.html", message: "User not found")
    end
  end
end
