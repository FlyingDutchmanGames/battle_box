defmodule BattleBoxWeb.UserControllerTest do
  use BattleBoxWeb.ConnCase

  @user_id Ecto.UUID.generate()

  describe "show" do
    test "trying to view a non existant user is a not found 404", %{conn: conn} do
      conn = conn |> get("/users/#{Ecto.UUID.generate()}")
      assert html_response(conn, 404) =~ "User not found"
    end

    test "you can view a user", %{conn: conn} do
      {:ok, user} = create_user(id: @user_id)
      conn = get(conn, "/users/#{user.username}")
      assert html_response(conn, 200) =~ @user_id
    end
  end

  describe "index" do
    test "it will show the users", %{conn: conn} do
      {:ok, user1} = create_user()
      {:ok, user2} = create_user()

      conn = get(conn, "/users")
      html = html_response(conn, 200)

      assert html =~ user1.username
      assert html =~ user2.username
    end
  end
end
