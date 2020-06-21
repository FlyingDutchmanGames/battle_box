defmodule BattleBoxWeb.Live.RobotGame.TerrainEditor do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.RobotGameView
  alias BattleBox.Games.RobotGame.Settings.Terrain

  def mount(_params, %{"terrain_base64" => terrain_base64}, socket) do
    terrain = Base.decode64!(terrain_base64)
    socket = assign_terrain(socket, terrain)
    {:ok, assign(socket, active: :normal, brush: 1)}
  end

  def handle_event("set-terrain-type", %{"terrain" => terrain}, socket) do
    terrain = String.to_existing_atom(terrain)
    {:noreply, assign(socket, active: terrain)}
  end

  def handle_event("reset", _event, socket) do
    {:noreply, assign_terrain(socket, Terrain.default())}
  end

  def handle_event("random", _event, %{assigns: %{rows: rows, cols: cols}} = socket) do
    data = IO.iodata_to_binary(for _ <- 1..(rows * cols), do: <<:random.uniform(3) - 1>>)
    terrain = <<rows::8, cols::8, data::binary>>
    {:noreply, assign_terrain(socket, terrain)}
  end

  def handle_event("apply-terrain-type", %{"x" => x, "y" => y}, socket) do
    x = String.to_integer(x)
    y = String.to_integer(y)

    brush = socket.assigns.brush - 1

    terrain =
      for(
        x <- (x - brush)..(x + brush),
        y <- (y - brush)..(y + brush),
        x > -1,
        y > -1,
        x < socket.assigns.rows,
        y < socket.assigns.cols,
        do: [x, y]
      )
      |> Enum.reduce(socket.assigns.terrain, fn loc, terrain ->
        Terrain.set_at_location(terrain, loc, socket.assigns.active)
      end)

    {:noreply, assign_terrain(socket, terrain)}
  end

  def handle_event("decrement-" <> thing, _events, socket)
      when thing in ["rows", "cols", "brush"] do
    thing = String.to_existing_atom(thing)
    {:noreply, assign(socket, thing, max(socket.assigns[thing] - 1, 1))}
  end

  def handle_event("increment-" <> thing, _events, socket)
      when thing in ["rows", "cols", "brush"] do
    thing = String.to_existing_atom(thing)

    case thing do
      :brush ->
        {:noreply, assign(socket, :brush, min(4, socket.assigns.brush + 1))}

      :rows ->
        rows = min(39, socket.assigns.rows + 1)
        terrain = Terrain.resize(socket.assigns.terrain, rows, socket.assigns.cols)
        {:noreply, assign_terrain(socket, terrain)}

      :cols ->
        cols = min(39, socket.assigns.cols + 1)
        terrain = Terrain.resize(socket.assigns.terrain, socket.assigns.rows, cols)
        {:noreply, assign_terrain(socket, terrain)}
    end
  end

  def render(assigns) do
    RobotGameView.render("_terrain_editor.html", assigns)
  end

  defp assign_terrain(socket, terrain) do
    %{rows: rows, cols: cols} = Terrain.dimensions(terrain)

    assign(socket,
      terrain_base64: Base.encode64(terrain),
      terrain: terrain,
      rows: rows,
      cols: cols
    )
  end
end
