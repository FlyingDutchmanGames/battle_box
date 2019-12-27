defmodule BattleBoxWeb.Router do
  use BattleBoxWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Phoenix.LiveView.Flash
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BattleBoxWeb do
    pipe_through :browser

    get "/", PageController, :index

    scope "/robot_game", RobotGame do
      get "/games/:game_id", GameController, :watch
    end

    scope "/test" do
      live("/counter", CounterLive)
    end
  end
end
