defmodule BattleBoxWeb.GameControllerTest do
  use BattleBoxWeb.ConnCase, async: false

  test "it will not 404 with a not real lobby", %{conn: conn} do
    conn
    |> get("/lobbies/FAKE/games")
    |> html_response(200)
  end

  describe "index" do
  end
end
