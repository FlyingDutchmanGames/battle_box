defmodule BattleBoxWeb.PageControllerTest do
  use BattleBoxWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "BattleBox"
  end
end
