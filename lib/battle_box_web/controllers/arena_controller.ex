defmodule BattleBoxWeb.ArenaController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Arena, Repo, User}
  alias BattleBoxWeb.PageView
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
      %Arena{} = arena -> render(conn, "show.html", arena: arena)
      nil -> render404(conn, "Arena (#{arena_name}) not found")
    end
  end

  def edit(%{assigns: %{current_user: %{id: user_id} = user}} = conn, %{"name" => name}) do
    Arena
    |> where(name: ^name, user_id: ^user_id)
    |> Repo.one()
    |> Arena.preload_game_settings()
    |> case do
      %Arena{} = arena ->
        changeset = Arena.changeset(arena)
        render(conn, "edit.html", changeset: changeset, arena: arena)

      nil ->
        render404(conn, "Arena (#{name}) Not Found for User (#{user.username})")
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

        pagination_info = pagination_info(params)
        to_page = to_page(conn, params, pagination_info)

        render(conn, "index.html",
          user: user,
          arenas: arenas,
          pagination_info: pagination_info,
          to_page: to_page
        )

      nil ->
        render404(conn, "User (#{username}) not found")
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
    |> Repo.one()
    |> Arena.preload_game_settings()
    |> case do
      nil ->
        render404(conn, "Arena (#{name}) Not Found for User (#{user.username})")

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

  defp render404(conn, message) do
    conn
    |> put_status(404)
    |> put_view(PageView)
    |> render("not_found.html", message: message)
  end

  defp to_page(conn, %{"user_username" => username}, %{per_page: per_page}) do
    fn page ->
      Routes.user_arena_path(conn, :index, username, %{page: page, per_page: per_page})
    end
  end
end
