defmodule BattleBoxWeb.LobbyController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Lobby, Repo}

  def new(conn, _params) do
    changeset = Lobby.changeset(%Lobby{})
    render(conn, "new.html", changeset: changeset)
  end

  def index(conn, %{"user_id" => user_id}) do
    lobbies = Lobby.with_user_id(user_id) |> Repo.all()
    render(conn, "index.html", lobbies: lobbies)
  end

  def create(%{assigns: %{user: user}} = conn, %{"lobby" => lobby}) do
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
        |> redirect(to: Routes.live_path(conn, BattleBoxWeb.Lobby, lobby.id))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
