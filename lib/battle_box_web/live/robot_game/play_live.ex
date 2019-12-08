defmodule BattleBoxWeb.RobotGame.PlayLive do
  alias BattleBoxWeb.RobotGameView
  alias BattleBox.Games.RobotGame.Game
  use Phoenix.LiveView

  def mount(_session, socket) do
    game = Game.new()
    robot = %{player_id: 10, location: {10, 10}}
    game = Game.add_robot(game, robot)
    {:ok, assign(socket, game: game)}
  end

  def render(assigns) do
    RobotGameView.render("play.html", assigns)
  end
end
