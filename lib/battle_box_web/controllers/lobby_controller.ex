defmodule BattleBoxWeb.LobbyController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Lobby, Repo, User}
  alias BattleBoxWeb.PageView

  def new(conn, _params) do
    changeset = Lobby.changeset(%Lobby{})
    render(conn, "new.html", changeset: changeset)
  end

  def show(conn, %{"name" => lobby_name}) do
    Repo.get_by(Lobby, name: lobby_name)
    |> Repo.preload(:user)
    |> case do
      %Lobby{} = lobby ->
        render(conn, "show.html", lobby: lobby)

      nil ->
        conn
        |> put_status(404)
        |> put_view(PageView)
        |> render("not_found.html", message: "Lobby (#{lobby_name}) not found")
    end
  end

  def index(conn, %{"user_username" => username}) do
    Repo.get_by(User, username: username)
    |> Repo.preload(:lobbies)
    |> case do
      %User{} = user ->
        render(conn, "index.html", user: user)

      nil ->
        conn
        |> put_status(404)
        |> put_view(PageView)
        |> render("not_found.html", message: "User (#{username}) not found")
    end
  end

  def create(%{assigns: %{current_user: user}} = conn, %{"lobby" => params}) do
    user
    |> Ecto.build_assoc(:lobbies)
    |> Lobby.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, _lobby} ->
        redirect(conn, to: Routes.user_lobby_path(conn, :index, user.username))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
