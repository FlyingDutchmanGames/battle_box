defmodule BattleBoxWeb.Live.RobotGame.TerrainEditor do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.RobotGameView
  alias BattleBox.Games.RobotGame.Settings.Terrain

  def mount(_params, %{"terrain_base64" => terrain_base64}, socket) do
    terrain = Base.decode64!(terrain_base64)
    socket = assign_terrain(socket, terrain)

    {:ok, assign(socket, active: :normal)}
  end

  def handle_event("set-terrain-type", %{"terrain" => terrain}, socket) do
    terrain = String.to_existing_atom(terrain)
    {:noreply, assign(socket, active: terrain)}
  end

  def handle_event("apply-terrain-type", %{"row" => row, "col" => col}, socket) do
    row = String.to_integer(row)
    col = String.to_integer(col)
    terrain = Terrain.set_at_location(socket.assigns.terrain, [row, col], socket.assigns.active)
    {:noreply, assign_terrain(socket, terrain)}
  end

  def render(assigns) do
    RobotGameView.render("_terrain_editor.html", assigns)
  end

  defp assign_terrain(socket, terrain) do
    %{rows: rows, cols: cols} = Terrain.dimensions2(terrain)

    assign(socket,
      terrain_base64: Base.encode64(terrain),
      terrain: terrain,
      rows: rows,
      cols: cols
    )
  end
end
