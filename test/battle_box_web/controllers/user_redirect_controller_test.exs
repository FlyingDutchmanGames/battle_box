defmodule BattleBoxWeb.UserRedirectControllerTest do
  use BattleBoxWeb.ConnCase

  @user_id Ecto.UUID.generate()

  test "it will redirect you to your user's lobbies", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id)
      |> get("/lobbies")

    assert redirected_to(conn, 302) =~ "/users/#{@user_id}/lobbies"
  end

  test "it will redirect you to your user's bots", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id)
      |> get("/bots")

    assert redirected_to(conn, 302) =~ "/users/#{@user_id}/bots"
  end

  test "it will redirect you to the user", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id)
      |> get("/me")

    assert redirected_to(conn, 302) =~ "/users/#{@user_id}"
  end
end
