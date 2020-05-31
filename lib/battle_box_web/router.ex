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

    resources "/games", GameController, only: [:show]

    resources "/users", UserController, only: [:show], param: "username" do
      get "/follow", FollowController, :follow

      resources "/bots", BotController, only: [:show, :index], param: "name" do
        get "/follow", FollowController, :follow
      end

      resources "/lobbies", LobbyController, only: [:show, :index], param: "name" do
        get "/follow", FollowController, :follow
        resources "/games", GameController, only: [:index]
      end
    end

    scope "/" do
      pipe_through :require_logged_in
      pipe_through :require_not_banned

      get "/me", UserRedirectController, :users
      get "/bots", UserRedirectController, :bots
      get "/lobbies", UserRedirectController, :lobbies

      resources "/keys", ApiKeyController
      resources "/bots", BotController, only: [:create, :new], param: "name"
      resources "/lobbies", LobbyController, only: [:create, :new], param: "name"
    end

    scope "/" do
      pipe_through :require_logged_in

      get "/banned", PageController, :banned
      post "/logout", PageController, :logout
    end

    scope "/auth" do
      get "/github/login", GithubLoginController, :github_login
      get "/github/callback", GithubLoginController, :github_callback
    end

    scope "/health" do
      get "/", HealthController, :health
      get "/database", HealthController, :db
      get "/info", HealthController, :info
    end

    scope "/admin", Admin, as: :admin do
      pipe_through :require_admin

      get "/", PageController, :index
      resources "/users", UserController, except: [:new, :create], param: "username"

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
