defmodule BattleBoxWeb.GameControllerTest do
  use BattleBoxWeb.ConnCase

  test "you can load it when there are no games", %{conn: conn} do
    conn = get(conn, "/games")
    assert html_response(conn, 200) =~ "Games"
  end
end
