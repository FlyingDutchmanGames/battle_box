defmodule BattleBoxWeb.Admin.UserControllerTest do
  use BattleBoxWeb.ConnCase, async: false
  alias BattleBox.User

  @username "foo"

  setup do
    {:ok, user} = create_user(username: @username)
    %{user: user}
  end

  setup %{conn: conn} do
    %{conn: signin(conn, is_admin: true)}
  end

  describe "index" do
    test "it shows some users", %{conn: conn} do
      conn = get(conn, "/admin/users/")
      assert html_response(conn, 200) =~ @username
    end
  end

  describe "show" do
    test "you can show a user", %{conn: conn} do
      conn = get(conn, "/admin/users/#{@username}")
      assert html_response(conn, 200) =~ "foo"
    end

    test "a fake user is a 404", %{conn: conn} do
      conn = get(conn, "/admin/users/fake")
      assert html_response(conn, 404) =~ "User (fake) Not Found"
    end
  end

  describe "edit" do
    test "a fake user is a 404", %{conn: conn} do
      conn = get(conn, "/admin/users/fake/edit")
      assert html_response(conn, 404) =~ "User (fake) Not Found"
    end

    test "You get a form back", %{conn: conn, user: user} do
      conn = get(conn, "/admin/users/#{user.username}/edit")
      html = html_response(conn, 200)
      {:ok, document} = Floki.parse_document(html)
      assert [_form] = Floki.find(document, "form:not(#logout)")
    end
  end

  describe "update" do
    test "you can update a user", %{user: user, conn: conn} do
      assert user.username == "foo"
      refute user.is_banned
      refute user.is_admin

      conn =
        put(conn, "/admin/users/#{user.username}", %{
          "user" => %{
            "username" => "new-username",
            "is_banned" => true,
            "is_admin" => true
          }
        })

      assert redirected_to(conn, 302) == "/admin/users/new-username"
      user = Repo.get(User, user.id)
      assert user.username == "new-username"
      assert user.is_banned
      assert user.is_admin
    end

    test "updating to something invalid returns errors", %{user: user, conn: conn} do
      assert user.username == "foo"

      conn =
        put(conn, "/admin/users/#{user.username}", %{
          "user" => %{"username" => "invalid username"}
        })

      assert html_response(conn, 200) =~ "Can only contain alphanumeric characters or hyphens"
      user = Repo.get(User, user.id)
      assert user.username == "foo"
    end
  end
end
