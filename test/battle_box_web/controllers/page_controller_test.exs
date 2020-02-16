defmodule BattleBoxWeb.PageControllerTest do
  use BattleBoxWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "BattleBox"
  end

  test "GET /login", %{conn: conn} do
    conn = get(conn, "/login")
    html = html_response(conn, 200)
    assert html =~ "Login with Github"
    assert html =~ Routes.github_login_path(conn, :github_login)
  end
end
