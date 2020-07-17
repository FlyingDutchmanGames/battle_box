defmodule BattleBoxWeb.Router do
  use BattleBoxWeb, :router
  import Phoenix.LiveDashboard.Router
  alias BattleBoxWeb.Plugs.{RequireAdmin, RequireLoggedIn, RequireNotBanned, FetchUser}

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug FetchUser
    plug :put_root_layout, {BattleBoxWeb.LayoutView, :root}
  end

  pipeline :api, do: plug(:accepts, ["json"])
  pipeline :require_admin, do: plug(RequireAdmin)
  pipeline :require_logged_in, do: plug(RequireLoggedIn)
  pipeline :require_not_banned, do: plug(RequireNotBanned)

  scope "/", BattleBoxWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/login", PageController, :login
    get "/watch", FollowController, :follow
    get "/games", GameController, :index

    resources "/games", GameController, only: [:show]

    scope "/docs" do
      get "/*path", DocsController, :docs
    end

    resources "/users", UserController, only: [:show, :index], param: "username" do
      get "/follow", FollowController, :follow
      resources "/games", GameController, only: [:index]

      resources "/bots", BotController, only: [:show, :index], param: "name" do
        get "/follow", FollowController, :follow
        resources "/games", GameController, only: [:index]
      end

      resources "/arenas", ArenaController, only: [:show, :index], param: "name" do
        get "/follow", FollowController, :follow
        resources "/games", GameController, only: [:index]
      end
    end

    scope "/" do
      pipe_through :require_logged_in
      pipe_through :require_not_banned

      get "/me", UserRedirectController, :users
      get "/bots", UserRedirectController, :bots
      get "/arenas", UserRedirectController, :arenas

      resources "/keys", ApiKeyController
      resources "/bots", BotController, only: [:create, :new], param: "name"
      resources "/arenas", ArenaController, only: [:create, :new], param: "name"

      resources "/users", UserController, only: [], param: "username" do
        resources "/arenas", ArenaController, only: [:edit, :update], param: "name"
        resources "/bots", BotController, only: [:edit, :update], param: "name"
      end
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
end
