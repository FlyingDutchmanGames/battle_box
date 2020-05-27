defmodule BattleBoxWeb.LobbyController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Lobby, Repo, User}
  alias BattleBoxWeb.PageView

  def new(conn, _params) do
    changeset = Lobby.changeset(%Lobby{})
    render(conn, "new.html", changeset: changeset)
  end

  def index(conn, %{"user_id" => user_name}) do
    Repo.get_by(User, user_name: user_name)
    |> Repo.preload(:lobbies)
    |> case do
      %User{} = user ->
        render(conn, "index.html", user: user)

      nil ->
        conn
        |> put_status(404)
        |> put_view(PageView)
        |> render("not_found.html", message: "User (#{user_name}) not found")
    end
  end

  def create(%{assigns: %{current_user: user}} = conn, %{"lobby" => params}) do
    user
    |> Ecto.build_assoc(:lobbies)
    |> Lobby.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, _lobby} ->
        redirect(conn, to: Routes.user_lobby_path(conn, :index, user.user_name))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
