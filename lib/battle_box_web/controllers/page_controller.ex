defmodule BattleBoxWeb.PageController do
  use BattleBoxWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
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
