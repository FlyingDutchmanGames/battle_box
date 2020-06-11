defmodule BattleBoxWeb.PageControllerTest do
  use BattleBoxWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Botskrieg"
  end

  test "GET /login", %{conn: conn} do
    conn = get(conn, "/login")
    html = html_response(conn, 200)
    assert html =~ "Login with Github"
    assert html =~ Routes.github_login_path(conn, :github_login)
  end

  test "POST /logout", %{conn: conn} do
    conn = signin(conn)
    conn = post(conn, "/logout")
    assert redirected_to(conn, 302) =~ "/"
  end

  describe "banned" do
    test "If you're not logged in, you get redirected to the login page", %{conn: conn} do
      conn = get(conn, "/banned")
      "/login" = redirected_to(conn, 302)
    end

    test "If you're banned you see it", %{conn: conn} do
      conn =
        conn
        |> signin(%{is_banned: true})
        |> get("/banned")

      assert html_response(conn, 200) =~ "You've been banned"
    end

    test "If you're not banned it tells you", %{conn: conn} do
      conn =
        conn
        |> signin(%{is_banned: false})
        |> get("/banned")

      assert html_response(conn, 200) =~ "You're not banned"
    end
  end
end
