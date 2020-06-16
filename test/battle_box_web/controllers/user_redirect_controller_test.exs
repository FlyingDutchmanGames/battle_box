defmodule BattleBoxWeb.UserRedirectControllerTest do
  use BattleBoxWeb.ConnCase

  @user_id Ecto.UUID.generate()

  test "it will redirect you to your user's arenas", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id, username: "FOO")
      |> get("/arenas")

    assert redirected_to(conn, 302) =~ "/users/FOO/arenas"
  end

  test "it will redirect you to your user's bots", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id, username: "BAR")
      |> get("/bots")

    assert redirected_to(conn, 302) =~ "/users/BAR/bots"
  end

  test "it will redirect you to the user", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id, username: "BAZ")
      |> get("/me")

    assert redirected_to(conn, 302) =~ "/users/BAZ"
  end
end
