defmodule BattleBoxWeb.Admin.UsersTest do
  use BattleBoxWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias BattleBox.{User, Repo}

  test "if you're not signed in you can't see that page", %{conn: conn} do
    conn = get(conn, "/admin/users")
    assert redirected_to(conn, 302) == "/"
  end

  test "if you are not an admin you can't see it", %{conn: conn} do
    conn =
      conn
      |> signin(%{is_admin: false})
      |> get("/admin/users")

    assert redirected_to(conn, 302) == "/"
  end

  describe "as an admin" do
    setup %{conn: conn} do
      conn = signin(conn, %{is_admin: true})
      %{conn: conn}
    end

    test "you can load the page", %{conn: conn} do
      {:ok, user1} = create_user()
      {:ok, user2} = create_user()

      {:ok, _view, html} = live(conn, "/admin/users")
      assert html =~ user1.id
      assert html =~ user2.id
    end

    test "you can ban and unban a user", %{conn: conn} do
      {:ok, user} = create_user(%{is_banned: false})
      refute user.is_banned

      {:ok, view, _html} = live(conn, "/admin/users")
      render_change(view, "adjust_ban", %{"_target" => ["ban", user.id]})

      user = Repo.get(User, user.id)
      assert user.is_banned

      render_change(view, "adjust_ban", %{"_target" => ["unban", user.id]})

      user = Repo.get(User, user.id)
      refute user.is_banned
    end
  end
end
