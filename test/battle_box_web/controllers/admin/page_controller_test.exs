defmodule BattleBoxWeb.Admin.PageControllerTest do
  use BattleBoxWeb.ConnCase

  describe "GET /admin" do
    test "If you're not logged in, it fails and redirects to /", %{conn: conn} do
      conn = get(conn, "/admin")
      assert redirected_to(conn, 302) =~ "/"
    end

    test "If you're not an admin, it fails and redirects to /", %{conn: conn} do
      conn =
        conn
        |> signin(is_admin: false)
        |> get("/admin")

      assert redirected_to(conn, 302) =~ "/"
    end

    test "you can see it if you're and admin", %{conn: conn} do
      conn =
        conn
        |> signin(is_admin: true)
        |> get("/admin")

      assert html_response(conn, 200) =~ "/ Admin"
    end
  end
end
