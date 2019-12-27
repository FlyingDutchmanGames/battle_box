defmodule BattleBoxWeb.RobotGame.GameController do
  alias BattleBoxWeb.RobotGame.WatchGameLive
  use BattleBoxWeb, :controller

  def watch(conn, %{"game_id" => game_id}) do
    live_render(conn, WatchGameLive, session: %{game_id: game_id})
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
