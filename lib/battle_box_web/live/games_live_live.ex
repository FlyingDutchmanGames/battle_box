defmodule BattleBoxWeb.GamesLiveLive do
  alias BattleBoxWeb.GamesView
  use BattleBoxWeb, :live_view
  alias BattleBox.GameEngine

  @refresh_rate_ms 1000

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(@refresh_rate_ms, :refresh)
    end

    games = GameEngine.get_live_games(game_engine())
    IO.inspect(games, label: "GAMES")
    {:ok, assign(socket, games: games)}
  end

  def handle_info(:refresh, socket) do
    games = GameEngine.get_live_games(game_engine())
    IO.inspect(games, label: "GAMES")
    {:noreply, assign(socket, :games, games)}
  end

  def render(assigns) do
    GamesView.render("live.html", assigns)
  end

  def game_engine do
    @game_engine_provider.game_engine()
  end
end
