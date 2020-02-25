defmodule BattleBoxWeb.GameController do
  use BattleBoxWeb, :controller
  alias BattleBox.{BattleBoxGame, Repo}

  def index(conn, params) do
    games = []
    render(conn, "index.html", games: games)
  end
end
