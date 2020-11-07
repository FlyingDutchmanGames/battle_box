defmodule BattleBoxWeb.PageController do
  use BattleBoxWeb, :controller

  def index(conn, _params) do
    navigation_options = [
      {"Docs", Routes.docs_path(conn, :docs, [])},
      {"Watch", Routes.follow_path(conn, :follow)},
      {"Play", Routes.human_path(conn, :play)}
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
