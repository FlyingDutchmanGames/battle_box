defmodule BattleBoxWeb.UserController do
  use BattleBoxWeb, :controller
  alias BattleBoxWeb.PageView
  alias BattleBox.{Repo, User}

  def show(conn, %{"username" => username}) do
    case Repo.get_by(User, username: username) do
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
