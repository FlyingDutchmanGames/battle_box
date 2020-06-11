defmodule BattleBoxWeb.UserController do
  use BattleBoxWeb, :controller
  alias BattleBoxWeb.PageView
  alias BattleBox.{Repo, User}
  import Ecto.Query

  def index(conn, params) do
    users =
      User
      |> order_by(asc: :inserted_at)
      |> paginate(params)
      |> Repo.all()

    pagination_info = pagination_info(params)
    to_page = to_page(conn, pagination_info)

    render(conn, "index.html", users: users, to_page: to_page, pagination_info: pagination_info)
  end

  def show(conn, %{"username" => username}) do
    case Repo.get_by(User, username: username) do
      %User{} = user ->
        render(conn, "show.html", user: user)

      nil ->
        conn
        |> put_status(404)
        |> put_view(PageView)
        |> render("not_found.html", message: "User not found")
    end
  end

  defp to_page(conn, %{per_page: per_page}) do
    fn page -> Routes.user_path(conn, :index, %{page: page, per_page: per_page}) end
  end
end
