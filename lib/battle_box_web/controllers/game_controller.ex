defmodule BattleBoxWeb.GameController do
  use BattleBoxWeb, :controller
  alias BattleBox.{BattleBoxGame, Repo}
  import Ecto.Query, only: [from: 2]

  def index(conn, params) do
    games =
      BattleBoxGame.base()
      |> order_by_inserted_at_desc()
      |> limit(25)
      |> Repo.all()
      |> Repo.preload([:lobby, :robot_game, battle_box_game_bots: [bot: :user]])

    render(conn, "index.html", games: games)
  end

  defp limit(query, num) do
    from foo in query, limit: ^num
  end

  defp order_by_inserted_at_desc(query) do
    from foo in query, order_by: [desc: foo.inserted_at]
  end
end
