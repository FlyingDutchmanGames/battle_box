defmodule BattleBoxWeb.GameController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Repo, Game}
  import BattleBoxWeb.Utilites.Paginator, only: [paginate: 2, pagination_info: 1]
  import Ecto.Query

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
      |> Enum.into(games: games, params: params)

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
