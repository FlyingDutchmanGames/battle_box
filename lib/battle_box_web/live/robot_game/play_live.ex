defmodule BattleBoxWeb.RobotGame.PlayLive do
  alias BattleBoxWeb.RobotGameView
  alias BattleBox.Games.RobotGame.Game
  use Phoenix.LiveView

  def mount(_session, socket) do
    {:ok, initialize(socket)}
  end

  def handle_event("select_robot", %{"robot-id" => robot_id}, socket) do
    new_selected = if robot_id == socket.assigns.selected, do: nil, else: robot_id
    {:noreply, assign(socket, selected: new_selected)}
  end

  def render(assigns) do
    RobotGameView.render("play.html", assigns)
  end

  def initialize(socket) do
    game = Game.new()

    robots = [
      %{player_id: "player_1", location: {9, 9}},
      %{player_id: "player_2", location: {10, 10}}
    ]

    game = Game.add_robots(game, robots)
    assign(socket, selected: nil, game: game)
  end
end
