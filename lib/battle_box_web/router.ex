defmodule BattleBoxWeb.Router do
  use BattleBoxWeb, :router
  alias BattleBox.User

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_user
    plug Phoenix.LiveView.Flash
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BattleBoxWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/login", PageController, :login
    get "/logout", LogoutController, :logout

    live("/live_games", GamesLiveLive)
    live("/games/:game_id", GameLive)

    scope "/auth" do
      get "/github/login", GithubLoginController, :github_login
      get "/github/callback", GithubLoginController, :github_callback
    end

    scope "/" do
      pipe_through :require_logged_in

      get "/connections", ConnectionsController, :index

      resources "/bots", BotController, only: [:create, :new]
      resources "/lobbies", LobbyController, only: [:create, :new]
    end

    resources "/bots", BotController, only: [:show]
    resources "/lobbies", LobbyController, only: [:show]
    live("/users/:user_id/connections", ConnectionsLive)

    scope "/robot_game", RobotGame do
      live("/play", PlayLive)
    end
  end

  defp require_logged_in(conn, _) do
    case conn.assigns.user do
      %User{} -> conn
      nil -> conn |> redirect(to: "/login") |> halt()
    end
  end

  defp fetch_user(conn, _) do
    with id when not is_nil(id) <- get_session(conn, "user_id"),
         %User{} = user <- User.get_by_id(id) do
      assign(conn, :user, user)
    else
      _ ->
        assign(conn, :user, nil)
    end
  end
end
