defmodule BattleBoxWeb.GameController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Repo, Game}
  import BattleBox.Utilities.Paginator, only: [paginate: 2, pagination_info: 1]
  import Ecto.Query

  def index(conn, params) do
    games =
      Game
      |> order_by(desc: :inserted_at)
      |> filter_lobbies(params)
      |> paginate(params)
      |> preload(game_bots: [bot: :user])
      |> Repo.all()

    pagination_info = pagination_info(params)
    to_page = to_page(conn, params, pagination_info)

    render(conn, "index.html", Map.merge(pagination_info, %{games: games, to_page: to_page}))
  end

  defp filter_lobbies(query, %{"lobby_name" => lobby_name}) do
    query
    |> join(:inner, [game], lobby in assoc(game, :lobby), as: :lobby)
    |> where([_game, lobby: lobby], lobby.name == ^lobby_name)
    |> preload([_game, lobby: lobby], lobby: lobby)
  end

  defp filter_lobbies(query, _), do: preload(query, :lobby)

  defp to_page(conn, %{"user_username" => username, "lobby_name" => lobby_name}, %{
         per_page: per_page
       }) do
    fn page ->
      Routes.user_lobby_game_path(conn, :index, username, lobby_name, %{
        page: page,
        per_page: per_page
      })
    end
  end
end
