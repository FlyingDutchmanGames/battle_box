defmodule BattleBoxWeb.Live.GameViewerTest do
  use BattleBoxWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias BattleBoxWeb.Live.GameViewer

  test "with a non existant ID, it renders not found", %{conn: conn} do
    id = Ecto.UUID.generate()
    {:ok, _view, html} = live_isolated(conn, GameViewer, session: %{"game_id" => id})

    assert html =~ "Game (#{id}) not found"
  end

  test "it can load a game from the database"
  test "it updates the turn when a button is pressed"
  test "it updates the turn when a live game updates"
  test "it updates the game when the game finishes"
  test "it updates the game when the game dies"
  test "it can accept a starting turn in the session"
end
