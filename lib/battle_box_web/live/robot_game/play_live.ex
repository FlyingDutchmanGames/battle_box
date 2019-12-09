defmodule BattleBoxWeb.RobotGame.PlayLive do
  alias BattleBoxWeb.RobotGameView
  alias BattleBox.Games.RobotGame.Game
  use Phoenix.LiveView

  def mount(_session, socket) do
    game = Game.new()

    robots = [
      %{player_id: "player_1", location: {9, 9}},
      %{player_id: "player_2", location: {10, 10}}
    ]

    game = Game.add_robots(game, robots)
    {:ok, assign(socket, game: game)}
  end

  def render(assigns) do
    RobotGameView.render("play.html", assigns)
  end
end
