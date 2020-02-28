defmodule BattleBoxWeb.GamesLiveLive do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.GameView
  alias BattleBox.GameEngine

  @refresh_rate_ms 1000

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(@refresh_rate_ms, :refresh)
    end

    games = GameEngine.get_live_games(game_engine())
    {:ok, assign(socket, games: games)}
  end

  def handle_info(:refresh, socket) do
    games = GameEngine.get_live_games(game_engine())
    {:noreply, assign(socket, :games, games)}
  end

  def render(assigns) do
    GameView.render("live.html", assigns)
  end
end
