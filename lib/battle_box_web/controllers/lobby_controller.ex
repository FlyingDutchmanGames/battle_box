defmodule BattleBoxWeb.LobbyController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Lobby, Repo, User}
  alias BattleBoxWeb.PageView

  def new(conn, _params) do
    changeset = Lobby.changeset(%Lobby{})
    render(conn, "new.html", changeset: changeset)
  end

  def index(conn, %{"user_id" => user_name}) do
    case Repo.get_by(User, github_login_name: user_name) do
      %User{id: id} ->
        lobbies = Lobby.with_user_id(id) |> Repo.all()
        render(conn, "index.html", lobbies: lobbies)

      nil ->
        conn
        |> put_status(404)
        |> put_view(PageView)
        |> render("not_found.html", message: "User (#{user_name}) not found")
    end
  end

  def create(%{assigns: %{current_user: user}} = conn, %{"lobby" => lobby}) do
    params =
      Map.merge(lobby, %{
        "user_id" => user.id,
        "game_type" => "robot_game",
        "game_acceptance_time_ms" => 1000
      })

    case Lobby.create(params) do
      {:ok, lobby} ->
        conn
        |> put_flash(:info, "Lobby")
        |> redirect(to: Routes.live_path(conn, BattleBoxWeb.Lobby, lobby.name))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
