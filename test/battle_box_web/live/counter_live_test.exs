defmodule BattleBoxWeb.CounterLiveTest do
  use BattleBoxWeb.ConnCase
  import Phoenix.LiveViewTest

  test "disconnected view", %{conn: conn} do
    conn = get(conn, "/test/counter")
    assert html_response(conn, 200) =~ "Counter: 0"
  end

  test "Can count", %{conn: conn} do
    assert {:ok, view, html} = live(conn, "/test/counter")
    assert html =~ "Counter: 0"
    assert render_click(view, "incr") =~ "Counter: 1"
    assert render_click(view, "incr") =~ "Counter: 2"
  end
end
