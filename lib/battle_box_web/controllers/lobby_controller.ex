defmodule BattleBoxWeb.LobbyController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Lobby, Repo, User}
  alias BattleBoxWeb.PageView
  import Ecto.Query

  def new(conn, %{"game_type" => game_type}) do
    changeset = Lobby.changeset(%Lobby{}, %{"game_type" => game_type})
    render(conn, "new.html", changeset: changeset)
  end

  def new(conn, _params) do
    render(conn, "game_type_select.html")
  end

  def show(conn, %{"name" => lobby_name}) do
    Repo.get_by(Lobby, name: lobby_name)
    |> Repo.preload(:user)
    |> case do
      %Lobby{} = lobby -> render(conn, "show.html", lobby: lobby)
      nil -> render404(conn, "Lobby (#{lobby_name}) not found")
    end
  end

  def edit(%{assigns: %{current_user: %{id: user_id} = user}} = conn, %{"name" => name}) do
    Lobby
    |> where(name: ^name, user_id: ^user_id)
    |> Repo.one()
    |> Lobby.preload_game_settings()
    |> case do
      %Lobby{} = lobby ->
        changeset = Lobby.changeset(lobby)
        render(conn, "edit.html", changeset: changeset, lobby: lobby)

      nil ->
        render404(conn, "Lobby (#{name}) Not Found for User (#{user.username})")
    end
  end

  def index(conn, %{"user_username" => username} = params) do
    Repo.get_by(User, username: username)
    |> case do
      %User{} = user ->
        lobbies =
          Lobby
          |> where(user_id: ^user.id)
          |> order_by(desc: :inserted_at)
          |> paginate(params)
          |> Repo.all()

        pagination_info = pagination_info(params)
        to_page = to_page(conn, params, pagination_info)

        render(conn, "index.html",
          user: user,
          lobbies: lobbies,
          pagination_info: pagination_info,
          to_page: to_page
        )

      nil ->
        render404(conn, "User (#{username}) not found")
    end
  end

  def create(%{assigns: %{current_user: user}} = conn, %{"lobby" => params}) do
    user
    |> Ecto.build_assoc(:lobbies)
    |> Lobby.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, lobby} ->
        redirect(conn, to: Routes.user_lobby_path(conn, :show, user.username, lobby.name))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def update(
        %{assigns: %{current_user: %{id: user_id} = user}} = conn,
        %{"name" => name, "lobby" => params}
      ) do
    Lobby
    |> where(name: ^name, user_id: ^user_id)
    |> Lobby.preload_game_settings()
    |> case do
      nil ->
        render404(conn, "Lobby (#{name}) Not Found for User (#{user.username})")

      %Lobby{} = lobby ->
        lobby
        |> Lobby.changeset(params)
        |> Repo.update()
        |> case do
          {:ok, lobby} ->
            redirect(conn, to: Routes.user_lobby_path(conn, :show, user.username, lobby.name))

          {:error, changeset} ->
            render(conn, "edit.html", changeset: changeset, lobby: lobby)
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
      Routes.user_lobby_path(conn, :index, username, %{page: page, per_page: per_page})
    end
  end
end
