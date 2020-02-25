defmodule BattleBoxWeb.GameLive do
  alias BattleBoxWeb.{PageView, RobotGameView}
  use BattleBoxWeb, :live_view
  alias BattleBox.GameEngine
  alias BattleBox.Games.RobotGame.Game

  def mount(%{"game_id" => game_id}, _session, socket) do
    if connected?(socket) do
      GameEngine.subscribe(game_engine(), "game:#{game_id}")
    end

    case get_game(game_id) do
      nil ->
        {:ok, assign(socket, :not_found, true)}

      game ->
        {:ok, assign(socket, :game, game)}
    end
  end

  def handle_info({:game_update, id}, %{assigns: %{game: %{id: id}}} = socket) do
    {:noreply, assign(socket, :game, get_game(id))}
  end

  def render(%{not_found: true}), do: PageView.render("not_found.html", message: "Game not found")
  def render(%{game: _} = assigns), do: RobotGameView.render("play.html", assigns)

  defp get_game(game_id) do
    case GameEngine.get_game(game_engine(), game_id) do
      nil -> Game.get_by_id_with_settings(game_id)
      %{game: game} -> game
    end
  end
end
