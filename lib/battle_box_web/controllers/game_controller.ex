defmodule BattleBoxWeb.GameController do
  use BattleBoxWeb, :controller
  alias BattleBoxWeb.PageView
  alias BattleBox.{Repo, User, Bot, Lobby, Game}
  import Ecto.Query

  @default_per_page 25
  @max_per_page 50

  def index(conn, params) do
    games =
      Game
      |> order_by(desc: :inserted_at)
      |> filter_lobbies(params)
      |> paginate(params)
      |> preload(game_bots: [bot: :user])
      |> Repo.all()

    render(conn, "index.html", games: games, params: params)
  end

  def show(conn, _params) do
  end

  defp filter_lobbies(query, %{"lobby_name" => lobby_name}) do
    query
    |> join(:inner, [game], lobby in assoc(game, :lobby), as: :lobby)
    |> where([_game, lobby: lobby], lobby.name == ^lobby_name)
    |> preload([_game, lobby: lobby], lobby: lobby)
  end

  defp filter_lobbies(query, _), do: preload(query, :lobby)

  defp paginate(query, params) do
    %{page: page, per_page: per_page} = parse_pagination_params(params)

    query
    |> limit(^per_page)
    |> offset(^(page * per_page))
  end

  defp parse_pagination_params(params) do
    page =
      case params["page"] do
        nil -> 0
        page -> String.to_integer(page)
      end

    per_page =
      with per_page when not is_nil(per_page) <- params["per_page"],
           per_page <- String.to_integer(per_page),
           per_page when per_page in 0..@max_per_page <- per_page do
        per_page
      else
        _ -> @default_per_page
      end

    %{page: page, per_page: per_page}
  end
end
