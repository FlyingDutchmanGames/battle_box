defmodule BattleBoxWeb.PageController do
  use BattleBoxWeb, :controller

  def index(conn, _params) do
    navigation_options = [
      {"Docs", nil},
      {"Users", Routes.user_path(conn, :index)},
      {"Watch", Routes.follow_path(conn, :follow)},
      {"Games", Routes.game_path(conn, :index)},
      if(conn.assigns[:current_user] && conn.assigns.current_user.is_admin,
        do: {"Admin", Routes.admin_page_path(conn, :index)},
        else: {:inaccessible, "Admin"}
      )
    ]

    render(conn, "index.html", navigation_options: navigation_options)
  end

  def login(conn, _params) do
    render(conn, "login.html")
  end

  def banned(conn, _params) do
    render(conn, "banned.html")
  end

  def logout(conn, _params) do
    conn
    |> delete_session(:user_id)
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
