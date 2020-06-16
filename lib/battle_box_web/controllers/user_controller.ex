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
        nav_segments = [
          {"Users", Routes.user_path(conn, :index)},
          {user.username, Routes.user_path(conn, :show, user.username)}
        ]

        nav_options = [
          {"Bots", Routes.user_bot_path(conn, :index, user.username)},
          {"Games", Routes.user_game_path(conn, :index, user.username)},
          {"Arenas", Routes.user_arena_path(conn, :index, user.username)},
          {"Follow", Routes.user_follow_path(conn, :follow, user.username)},
          if(conn.assigns[:current_user] && user.id == conn.assigns.current_user.id,
            do: {"Keys", Routes.api_key_path(conn, :index)},
            else: {:inaccessible, "Keys"}
          )
        ]

        render(conn, "show.html", user: user, nav_segments: nav_segments, nav_options: nav_options)

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
