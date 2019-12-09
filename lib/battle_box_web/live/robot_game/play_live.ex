defmodule BattleBoxWeb.RobotGame.PlayLive do
  alias BattleBoxWeb.RobotGameView
  alias BattleBox.Games.RobotGame.Game
  use Phoenix.LiveView

  def mount(_session, socket) do
    {:ok, initialize(socket)}
  end

  def handle_event("select-robot", %{"robot-id" => robot_id}, socket) do
    new_selected = if robot_id == socket.assigns.selected, do: nil, else: robot_id
    {:noreply, assign(socket, selected: new_selected)}
  end

  def handle_event("terrain-click", _, socket) do
    {:noreply, assign(socket, selected: nil)}
  end

  def handle_event("create-move", params, socket) do
    type =
      case params["type"] do
        "attack" -> :attack
        "move" -> :move
        "suicide" -> :suicide
        "guard" -> :guard
      end

    robot_id = Map.fetch!(params, "robot-id")
    {target_row, ""} = Integer.parse(Map.fetch!(params, "target-row"))
    {target_col, ""} = Integer.parse(Map.fetch!(params, "target-col"))

    move = %{
      type: type,
      robot_id: robot_id,
      target: {target_row, target_col}
    }

    socket = update_in(socket.assigns.moves, fn moves -> Map.put(moves, robot_id, move) end)
    {:noreply, assign(socket, selected: nil)}
  end

  def render(assigns) do
    RobotGameView.render("play.html", assigns)
  end

  def initialize(socket) do
    game = Game.new()

    robots = [
      %{player_id: "player_1", location: {10, 9}, id: "1"},
      %{player_id: "player_2", location: {10, 10}, id: "2"},
      %{player_id: "player_1", location: {11, 11}, id: "3"},
      %{player_id: "player_2", location: {12, 12}, id: "4"}
    ]

    game = Game.add_robots(game, robots)
    assign(socket, selected: nil, game: game, moves: %{})
  end

  defp enrich_moves(game, moves) do
    moves
    |> Enum.map(fn move ->
      robot = Game.get_robot(game, move.robot_id)
      Map.merge(move, %{robot_location: robot.location})
    end)
  end
end
