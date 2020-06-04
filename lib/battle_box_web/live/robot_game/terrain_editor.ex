defmodule BattleBoxWeb.Live.RobotGame.TerrainEditor do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.RobotGameView
  alias BattleBox.Games.RobotGame.Settings.Terrain

  def mount(_params, %{"terrain_base64" => terrain_base64}, socket) do
    terrain = Base.decode64!(terrain_base64)
    socket = assign_terrain(socket, terrain)
    {:ok, assign(socket, active: :normal, brush_width: 1)}
  end

  def handle_event("set-terrain-type", %{"terrain" => terrain}, socket) do
    terrain = String.to_existing_atom(terrain)
    {:noreply, assign(socket, active: terrain)}
  end

  def handle_event("reset", _event, socket) do
    {:noreply, assign_terrain(socket, Terrain.default())}
  end

  def handle_event("random", _event, %{assigns: %{rows: rows, cols: cols}} = socket) do
    data = IO.iodata_to_binary(for i <- 1..(rows * cols), do: <<:random.uniform(3) - 1>>)
    terrain = <<rows::8, cols::8, data::binary>>
    {:noreply, assign_terrain(socket, terrain)}
  end

  def handle_event("apply-terrain-type", %{"row" => row, "col" => col}, socket) do
    row = String.to_integer(row)
    col = String.to_integer(col)

    brush = socket.assigns.brush_width - 1

    terrain =
      for(
        r <- (row - brush)..(row + brush),
        c <- (col - brush)..(col + brush),
        r > 0,
        c > 0,
        r < socket.assigns.rows,
        c < socket.assigns.cols,
        do: [r, c]
      )
      |> Enum.reduce(socket.assigns.terrain, fn loc, terrain ->
        Terrain.set_at_location(terrain, loc, socket.assigns.active)
      end)

    {:noreply, assign_terrain(socket, terrain)}
  end

  def handle_event("set-dimensions", %{"rows" => rows, "cols" => cols}, socket) do
    rows = String.to_integer(rows)
    cols = String.to_integer(cols)
    terrain = Terrain.resize(socket.assigns.terrain, rows, cols)
    {:noreply, assign_terrain(socket, terrain)}
  end

  def handle_event("set-brush-width", %{"brush-width" => brush_width}, socket) do
    brush_width = String.to_integer(brush_width)
    {:noreply, assign(socket, brush_width: brush_width)}
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
