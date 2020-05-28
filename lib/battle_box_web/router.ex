defmodule BattleBoxWeb.Router do
  use BattleBoxWeb, :router
  alias BattleBox.{Repo, User}
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_user
    plug :put_root_layout, {BattleBoxWeb.LayoutView, :root}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BattleBoxWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/login", PageController, :login

    scope "/" do
      pipe_through :require_logged_in

      get "/banned", PageController, :banned
      post "/logout", PageController, :logout
    end

    scope "/health" do
      get "/", HealthController, :health
      get "/database", HealthController, :db
      get "/info", HealthController, :info
    end

    scope "/auth" do
      get "/github/login", GithubLoginController, :github_login
      get "/github/callback", GithubLoginController, :github_callback
    end

    live("/games/:game_id", Game)
    live("/users/:user_id/bots", Bots)
    live("/bot_servers/:bot_server_id/follow", BotServerFollow)

    scope "/" do
      pipe_through :require_logged_in
      pipe_through :require_not_banned

      get "/me", UserRedirectController, :users
      get "/bots", UserRedirectController, :bots
      get "/lobbies", UserRedirectController, :lobbies

      resources "/keys", ApiKeyController
      resources "/bots", BotController, only: [:create, :new]

      resources "/lobbies", LobbyController, only: [:new, :index, :create] do
        resources "/games", GameController, only: [:index]
      end
    end

    live("/lobbies/:id", Lobby)

    resources "/users", UserController, only: [:show] do
      resources "/games", GameController, only: [:index]
      resources "/lobbies", LobbyController, only: [:index]

      resources "/bots", BotController, only: [:show] do
        resources "/games", GameController, only: [:index]
      end
    end

    scope "/admin", Admin do
      pipe_through :require_admin
      live("/users", Users)
      live_dashboard "/dashboard", metrics: BattleBoxWeb.Telemetry
    end
  end

  defp require_logged_in(conn, _) do
    case conn.assigns.current_user do
      %User{} -> conn
      nil -> conn |> redirect(to: "/login") |> halt()
    end
  end

  defp require_not_banned(conn, _) do
    case conn.assigns.current_user do
      %User{is_banned: false} -> conn
      _ -> conn |> redirect(to: "/banned") |> halt()
    end
  end

  defp require_admin(conn, _) do
    case conn.assigns.current_user do
      %User{is_admin: true} -> conn
      _ -> conn |> redirect(to: "/") |> halt()
    end
  end

  defp fetch_user(conn, _) do
    with id when not is_nil(id) <- get_session(conn, "user_id"),
         %User{} = user <- Repo.get(User, id) do
      assign(conn, :current_user, user)
    else
      _ ->
        assign(conn, :current_user, nil)
    end
  end
end
