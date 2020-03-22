defmodule BattleBoxWeb.BotsServerFollowTest do
  use BattleBoxWeb.ConnCase
  import Phoenix.LiveViewTest

  # @bot_server_id Ecto.UUID.generate()

  test "if there isn't a running bot server it returns not found", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/bot_servers/#{Ecto.UUID.generate()}/follow")
    assert html =~ "Not Found"
    assert html =~ "Probably Dead"
  end
end
