defmodule BattleBoxWeb.ConnectionsController do
  use BattleBoxWeb, :controller
  alias BattleBoxWeb.ConnectionsLive

  def index(%{assigns: %{user: user}} = conn, _params) do
    conn
    |> redirect(to: Routes.live_path(conn, ConnectionsLive, user.id))
  end
end
