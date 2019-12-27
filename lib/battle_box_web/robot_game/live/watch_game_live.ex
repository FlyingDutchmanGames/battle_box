defmodule BattleBoxWeb.RobotGame.WatchGameLive do
  use Phoenix.LiveView
  alias BattleBoxWeb.{RobotGameView, PageView}
  alias BattleBox.Games.RobotGame.Game

  def mount(%{game_id: game_id}, socket) do
    if connected?(socket),
      do: {:ok, initialize(socket, game_id)},
      else: {:ok, assign(socket, loading: true)}
  end

  def render(assigns) do
    if assigns[:loading],
      do: PageView.render("loading.html", assigns),
      else: RobotGameView.render("watch.html", assigns)
  end

  defp initialize(socket, game_id) do
    game = Game.get_by_id(game_id)
    assign(socket, game: game)
  end
end
