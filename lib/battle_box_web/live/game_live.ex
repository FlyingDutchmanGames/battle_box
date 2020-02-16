defmodule BattleBoxWeb.GameLive do
  alias BattleBoxWeb.{PageView, RobotGameView}
  use BattleBoxWeb, :live_view
  alias BattleBox.GameEngine

  def mount(%{"game_id" => game_id}, _session, socket) do
    case GameEngine.get_game(game_engine(), game_id) do
      nil ->
        {:ok, assign(socket, :not_found, true)}

      game ->
        {:ok, assign(socket, :game, game)}
    end
  end

  def render(%{not_found: true}), do: PageView.render("not_found.html", message: "Game not found")
  def render(%{game: game} = assigns), do: RobotGameView.render("play.html", assigns)
end
