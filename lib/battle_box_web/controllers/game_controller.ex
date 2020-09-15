defmodule BattleBoxWeb.GameController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Repo, Game, Bot, User, Arena}
  import Ecto.Query

  def index(conn, params) do
    with {:ok, subject} <- load_subject(params) do
      games =
        Game
        |> order_by(desc: :inserted_at)
        |> paginate(params)
        |> filter(subject)
        |> Repo.all()
        |> Repo.preload(game_bots: [bot: :user], arena: [:user])

      pagination_info = pagination_info(params)
      to_page = to_page(conn, subject, pagination_info)

      render(conn, "index.html", %{
        pagination_info: pagination_info,
        games: games,
        to_page: to_page,
        nav_segments: [subject, "Games"]
      })
    else
      {:error, {:not_found, subject}} -> render404(conn, subject)
    end
  end

  defp filter(query, subject) do
    case subject do
      :no_subject ->
        query

      %Arena{id: arena_id} ->
        query
        |> where(arena_id: ^arena_id)

      %Bot{id: bot_id} ->
        query
        |> join(:inner, [game], game_bot in assoc(game, :game_bots), as: :game_bot)
        |> where([_game, game_bot: game_bot], game_bot.bot_id == ^bot_id)

      %User{id: user_id} ->
        query
        |> join(:inner, [game], game_bot in assoc(game, :game_bots), as: :game_bot)
        |> join(:inner, [_game, game_bot: game_bot], bot in assoc(game_bot, :bot), as: :bot)
        |> where([_game, bot: bot], bot.user_id == ^user_id)
    end
  end

  defp load_subject(params) do
    case params do
      %{"arena_name" => arena_name, "user_username" => username} ->
        Arena
        |> where(name: ^arena_name)
        |> join(:inner, [arena], user in assoc(arena, :user), as: :user)
        |> where([_arena, user: user], user.username == ^username)
        |> preload(:user)
        |> Repo.one()
        |> case do
          nil -> {:error, {:not_found, {Arena, arena_name, username}}}
          arena -> {:ok, arena}
        end

      %{"bot_name" => bot_name, "user_username" => username} ->
        Bot
        |> where(name: ^bot_name)
        |> join(:inner, [bot], user in assoc(bot, :user), as: :user)
        |> where([_bot, user: user], user.username == ^username)
        |> preload(:user)
        |> Repo.one()
        |> case do
          nil -> {:error, {:not_found, {Bot, bot_name, username}}}
          bot -> {:ok, bot}
        end

      %{"user_username" => username} ->
        case Repo.get_by(User, username: username) do
          nil -> {:error, {:not_found, {User, username}}}
          user -> {:ok, user}
        end

      _ ->
        {:ok, :no_subject}
    end
  end

  defp to_page(conn, subject, %{per_page: per_page}) do
    case subject do
      :no_subject ->
        &Routes.game_path(conn, :index, %{page: &1, per_page: per_page})

      %Arena{user: %{username: username}, name: name} ->
        &Routes.user_arena_game_path(conn, :index, username, name, %{page: &1, per_page: per_page})

      %Bot{user: %{username: username}, name: name} ->
        &Routes.user_bot_game_path(conn, :index, username, name, %{page: &1, per_page: per_page})

      %User{username: username} ->
        &Routes.user_game_path(conn, :index, username, %{page: &1, per_page: per_page})
    end
  end
end
