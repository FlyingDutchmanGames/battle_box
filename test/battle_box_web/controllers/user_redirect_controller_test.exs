defmodule BattleBoxWeb.UserRedirectControllerTest do
  use BattleBoxWeb.ConnCase

  @user_id Ecto.UUID.generate()

  test "it will redirect you to your user's lobbies", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id, user_name: "FOO")
      |> get("/lobbies")

    assert redirected_to(conn, 302) =~ "/users/FOO/lobbies"
  end

  test "it will redirect you to your user's bots", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id, user_name: "BAR")
      |> get("/bots")

    assert redirected_to(conn, 302) =~ "/users/BAR/bots"
  end

  test "it will redirect you to the user", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id, user_name: "BAZ")
      |> get("/me")

    assert redirected_to(conn, 302) =~ "/users/BAZ"
  end
end
