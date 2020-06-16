defmodule BattleBoxWeb.GameController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Repo, Game, Arena, GameEngine}
  import Ecto.Query

  def index(conn, %{"arena_name" => arena_name} = params) do
    arena =
      Repo.get_by(Arena, name: arena_name)
      |> Repo.preload(:user)

    games =
      Game
      |> order_by(desc: :inserted_at)
      |> filter_arenas(params)
      |> paginate(params)
      |> preload(game_bots: [bot: :user])
      |> Repo.all()

    pagination_info = pagination_info(params)
    to_page = to_page(conn, params, pagination_info)
    assigns = %{pagination_info: pagination_info, games: games, to_page: to_page, arena: arena}

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

  defp filter_arenas(query, %{"arena_name" => arena_name}) do
    query
    |> join(:inner, [game], arena in assoc(game, :arena), as: :arena)
    |> where([_game, arena: arena], arena.name == ^arena_name)
    |> preload([_game, arena: arena], arena: arena)
  end

  defp filter_arenas(query, _), do: preload(query, :arena)

  defp to_page(conn, %{"user_username" => username, "arena_name" => arena_name}, %{
         per_page: per_page
       }) do
    fn page ->
      Routes.user_arena_game_path(conn, :index, username, arena_name, %{
        page: page,
        per_page: per_page
      })
    end
  end
end
