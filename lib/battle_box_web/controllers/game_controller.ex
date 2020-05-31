defmodule BattleBoxWeb.GameController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Repo, Game, GameEngine}
  import BattleBox.Utilities.Paginator, only: [paginate: 2, pagination_info: 1]
  import Ecto.Query

  def show(conn, %{"id" => id} = params) do
    game = GameEngine.get_game(game_engine(), id)
    render(conn, "show.html", id: id, game: game, follow: params["follow"])
  end

  def index(conn, params) do
    games =
      Game
      |> order_by(desc: :inserted_at)
      |> filter_lobbies(params)
      |> paginate(params)
      |> preload(game_bots: [bot: :user])
      |> Repo.all()

    assigns =
      params
      |> pagination_info
      |> Enum.into([])
      |> Keyword.merge(games: games, params: params)

    render(conn, "index.html", assigns)
  end

  defp filter_lobbies(query, %{"lobby_name" => lobby_name}) do
    query
    |> join(:inner, [game], lobby in assoc(game, :lobby), as: :lobby)
    |> where([_game, lobby: lobby], lobby.name == ^lobby_name)
    |> preload([_game, lobby: lobby], lobby: lobby)
  end

  defp filter_lobbies(query, _), do: preload(query, :lobby)
end
