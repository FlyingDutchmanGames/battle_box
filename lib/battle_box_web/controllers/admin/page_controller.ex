defmodule BattleBoxWeb.Admin.PageController do
  use BattleBoxWeb, :controller

  def index(conn, _params) do
    nav_segments = [:admin]

    nav_options = [
      {"Users", Routes.admin_user_path(conn, :index)},
      {"Dashboard", Routes.live_dashboard_path(conn, :home)}
    ]

    render(conn, "index.html", nav_segments: nav_segments, nav_options: nav_options)
  end
end
