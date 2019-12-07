defmodule BattleBoxWeb.RobotGame.PlayLive do
  alias BattleBoxWeb.RobotGameView
  alias BattleBox.Games.RobotGame.Game
  use Phoenix.LiveView

  def mount(_session, socket) do
    game = Game.new()
    {:ok, assign(socket, game: game)}
  end

  def render(assigns) do
    RobotGameView.render("play.html", assigns)
  end
end
