defmodule BattleBoxWeb.GameController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Repo, Game, Lobby, GameEngine}
  import BattleBox.Utilities.Paginator, only: [paginate: 2, pagination_info: 1]
  import Ecto.Query

  def index(conn, %{"lobby_name" => lobby_name} = params) do
    lobby =
      Repo.get_by(Lobby, name: lobby_name)
      |> Repo.preload(:user)

    games =
      Game
      |> order_by(desc: :inserted_at)
      |> filter_lobbies(params)
      |> paginate(params)
      |> preload(game_bots: [bot: :user])
      |> Repo.all()

    pagination_info = pagination_info(params)
    to_page = to_page(conn, params, pagination_info)
    assigns = %{pagination_info: pagination_info, games: games, to_page: to_page, lobby: lobby}

    render(conn, "index.html", assigns)
  end

  def show(conn, %{"id" => id} = params) do
    game_pid =
      case GameEngine.get_game_server(game_engine(), id) do
        %{pid: pid} -> pid
        nil -> nil
      end

    render(conn, "show.html",
      id: id,
      game_pid: game_pid,
      follow: params["follow"],
      turn: params["turn"]
    )
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
