defmodule BattleBoxWeb.ArenaController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Arena, Repo, User}
  import Ecto.Query

  def new(conn, %{"game_type" => game_type}) do
    changeset = Arena.changeset(%Arena{}, %{"game_type" => game_type})
    render(conn, "new.html", changeset: changeset)
  end

  def new(conn, _params) do
    render(conn, "game_type_select.html")
  end

  def show(conn, %{"name" => arena_name}) do
    Repo.get_by(Arena, name: arena_name)
    |> Repo.preload(:user)
    |> case do
      %Arena{} = arena ->
        nav_segments = [{arena.user, :arenas}, arena.name]

        nav_options = [
          {"Scoreboard",
           Routes.user_arena_arena_path(conn, :scoreboard, arena.user.username, arena_name)},
          {:games, arena},
          {:follow, arena},
          if(conn.assigns[:current_user] && conn.assigns.current_user.id == arena.user_id,
            do: {:edit, arena},
            else: {:inaccessible, "Edit"}
          )
        ]

        render(conn, "show.html",
          arena: arena,
          nav_segments: nav_segments,
          nav_options: nav_options
        )

      nil ->
        render404(conn, {Arena, arena_name})
    end
  end

  def scoreboard(conn, %{"arena_name" => arena_name}) do
    Repo.get_by(Arena, name: arena_name)
    |> Repo.preload(:user)
    |> case do
      %Arena{} = arena ->
        nav_segments = [{arena.user, :arenas}, arena, "Scoreboard"]
        render(conn, "scoreboard.html", arena: arena, nav_segments: nav_segments)

      nil ->
        render404(conn, {Arena, arena_name})
    end
  end

  def edit(%{assigns: %{current_user: %{id: user_id} = user}} = conn, %{"name" => name}) do
    Arena
    |> where(name: ^name, user_id: ^user_id)
    |> preload(:user)
    |> Repo.one()
    |> Arena.preload_game_settings()
    |> case do
      %Arena{} = arena ->
        changeset = Arena.changeset(arena)
        render(conn, "edit.html", changeset: changeset, arena: arena)

      nil ->
        render404(conn, {Arena, name, user.username})
    end
  end

  def index(conn, %{"user_username" => username} = params) do
    Repo.get_by(User, username: username)
    |> case do
      %User{} = user ->
        arenas =
          Arena
          |> where(user_id: ^user.id)
          |> order_by(desc: :inserted_at)
          |> paginate(params)
          |> Repo.all()

        nav_segments = [user, "Arenas"]

        nav_options = [
          if(conn.assigns[:current_user] && user.id == conn.assigns.current_user.id,
            do: {:new, :arena},
            else: {:inaccessible, "New"}
          )
        ]

        pagination_info = pagination_info(params)
        to_page = to_page(conn, params, pagination_info)

        render(conn, "index.html",
          user: user,
          arenas: arenas,
          nav_options: nav_options,
          nav_segments: nav_segments,
          pagination_info: pagination_info,
          to_page: to_page
        )

      nil ->
        render404(conn, {User, username})
    end
  end

  def create(%{assigns: %{current_user: user}} = conn, %{"arena" => params}) do
    user
    |> Ecto.build_assoc(:arenas)
    |> Arena.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, arena} ->
        redirect(conn, to: Routes.user_arena_path(conn, :show, user.username, arena.name))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def update(
        %{assigns: %{current_user: %{id: user_id} = user}} = conn,
        %{"name" => name, "arena" => params}
      ) do
    Arena
    |> where(name: ^name, user_id: ^user_id)
    |> preload(:user)
    |> Repo.one()
    |> Arena.preload_game_settings()
    |> case do
      nil ->
        render404(conn, {Arena, name, user.username})

      %Arena{} = arena ->
        arena
        |> Arena.changeset(params)
        |> Repo.update()
        |> case do
          {:ok, arena} ->
            redirect(conn, to: Routes.user_arena_path(conn, :show, user.username, arena.name))

          {:error, changeset} ->
            render(conn, "edit.html", changeset: changeset, arena: arena)
        end
    end
  end

  defp to_page(conn, %{"user_username" => username}, %{per_page: per_page}) do
    fn page ->
      Routes.user_arena_path(conn, :index, username, %{page: page, per_page: per_page})
    end
  end
end
