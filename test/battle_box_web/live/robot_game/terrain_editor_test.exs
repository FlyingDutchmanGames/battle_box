defmodule BattleBoxWeb.Live.RobotGame.TerrainEditorTest do
  use BattleBoxWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias BattleBox.Games.RobotGame.Settings.Terrain
  alias BattleBoxWeb.Live.RobotGame.TerrainEditor

  @base64_default Base.encode64(Terrain.default())

  test "it renders on the screen", %{conn: conn} do
    {:ok, _view, html} =
      live_isolated(conn, TerrainEditor, session: %{"terrain_base64" => @base64_default})

    {:ok, document} = Floki.parse_document(html)
    assert "Rows (19)" = Floki.find(document, "#rows") |> Floki.text()
    assert "Cols (19)" = Floki.find(document, "#cols") |> Floki.text()
    assert "Brush Width (1)" = Floki.find(document, "#brush-width") |> Floki.text()
  end

  test "You can adjust the rows, cols and brush width", %{conn: conn} do
    {:ok, view, html} =
      live_isolated(conn, TerrainEditor, session: %{"terrain_base64" => @base64_default})

    {:ok, document} = Floki.parse_document(html)

    assert "Rows (19)" = Floki.find(document, "#rows") |> Floki.text()
    assert "Cols (19)" = Floki.find(document, "#cols") |> Floki.text()
    assert "Brush Width (1)" = Floki.find(document, "#brush-width") |> Floki.text()

    view |> element("#rows-increment") |> render_click()
    view |> element("#cols-increment") |> render_click()
    view |> element("#brush-increment") |> render_click()
    html = view |> element("#brush-increment") |> render_click()

    {:ok, document} = Floki.parse_document(html)

    assert "Rows (20)" = Floki.find(document, "#rows") |> Floki.text()
    assert "Cols (20)" = Floki.find(document, "#cols") |> Floki.text()
    assert "Brush Width (3)" = Floki.find(document, "#brush-width") |> Floki.text()

    view |> element("#rows-decrement") |> render_click()
    view |> element("#rows-decrement") |> render_click()
    view |> element("#brush-decrement") |> render_click()
    view |> element("#brush-decrement") |> render_click()
    view |> element("#cols-decrement") |> render_click()
    html = view |> element("#cols-decrement") |> render_click()

    {:ok, document} = Floki.parse_document(html)

    assert "Rows (18)" = Floki.find(document, "#rows") |> Floki.text()
    assert "Cols (18)" = Floki.find(document, "#cols") |> Floki.text()
    assert "Brush Width (1)" = Floki.find(document, "#brush-width") |> Floki.text()
  end

  test "you can set the terrain type", %{conn: conn} do
    {:ok, view, html} =
      live_isolated(conn, TerrainEditor, session: %{"terrain_base64" => @base64_default})

    {:ok, document} = Floki.parse_document(html)
    assert "normal" = Floki.find(document, ".active") |> Floki.text()

    html = view |> element("#choice-spawn") |> render_click()
    {:ok, document} = Floki.parse_document(html)
    assert "spawn" = Floki.find(document, ".active") |> Floki.text()
  end

  test "random randomized and reset resets that the board", %{conn: conn} do
    {:ok, view, html} =
      live_isolated(conn, TerrainEditor, session: %{"terrain_base64" => @base64_default})

    assert @base64_default == get_base64_terrain(html)
    html = view |> element("#randomize") |> render_click()
    assert @base64_default != get_base64_terrain(html)
    html = view |> element("#reset") |> render_click()
    assert @base64_default == get_base64_terrain(html)
  end

  test "apply terrain type", %{conn: conn} do
    {:ok, view, html} =
      live_isolated(conn, TerrainEditor, session: %{"terrain_base64" => @base64_default})

    assert terrain_at_location(html, 0, 0) == :inaccessible
    html = view |> element("div[loc='[0, 0]']") |> render_click
    assert terrain_at_location(html, 0, 0) == :normal
  end

  defp terrain_at_location(html, row, col) do
    html
    |> get_base64_terrain
    |> Base.decode64!()
    |> Terrain.at_location([row, col])
  end

  defp get_base64_terrain(html) do
    {:ok, document} = Floki.parse_document(html)

    [terrain] =
      document
      |> Floki.find("#lobby_robot_game_settings_terrain_base64")
      |> Floki.attribute("value")

    String.trim(terrain)
  end
end
