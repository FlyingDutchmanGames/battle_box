defmodule BattleBoxWeb.ConnectionsControllerTest do
  use BattleBoxWeb.ConnCase

  @user_id Ecto.UUID.generate()

  test "it will redirect you to your user's connections", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id)
      |> get("/connections")

    assert redirected_to(conn, 302) =~ "/users/#{@user_id}/connections"
  end
end
