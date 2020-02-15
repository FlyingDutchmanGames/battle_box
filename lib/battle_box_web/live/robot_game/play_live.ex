defmodule BattleBoxWeb.RobotGame.PlayLive do
  alias BattleBoxWeb.RobotGameView
  alias BattleBox.Games.RobotGame.{Game, Game.Logic}
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, initialize(socket)}
  end

  def handle_event("select-robot", %{"robot-id" => robot_id}, socket) do
    new_selected = if robot_id == socket.assigns.selected, do: nil, else: robot_id
    {:noreply, assign(socket, selected: new_selected)}
  end

  def handle_event("terrain-click", _, socket) do
    {:noreply, assign(socket, selected: nil)}
  end

  def handle_event("run-move", _params, socket) do
    moves = Map.values(socket.assigns.moves)
    game = Logic.calculate_turn(socket.assigns.game, %{player_1: moves, player_2: []})

    {:noreply, assign(socket, game: game, selected: nil, moves: %{})}
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
    assign(socket, selected: nil, game: game, moves: %{})
  end
end
