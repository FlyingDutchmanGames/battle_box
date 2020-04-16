defmodule BattleBoxWeb.UserControllerTest do
  use BattleBoxWeb.ConnCase

  @fetched_user_id Ecto.UUID.generate()

  test "trying to view a non existant user is a not found 404", %{conn: conn} do
    conn = conn |> get("/users/#{Ecto.UUID.generate()}")
    assert html_response(conn, 404) =~ "User not found"
  end

  test "you can view a user", %{conn: conn} do
    {:ok, _user} = create_user(id: @fetched_user_id)
    conn = get(conn, "/users/#{@fetched_user_id}")
    assert html_response(conn, 200) =~ @fetched_user_id
  end
end
