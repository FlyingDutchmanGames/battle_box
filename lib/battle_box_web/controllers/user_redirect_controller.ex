defmodule BattleBoxWeb.UserRedirectController do
  use BattleBoxWeb, :controller
  alias BattleBoxWeb.ConnectionsLive

  def connections(%{assigns: %{user: user}} = conn, _params) do
    redirect(conn, to: Routes.live_path(conn, ConnectionsLive, user.id))
  end

  def lobbies(%{assigns: %{user: user}} = conn, _params) do
    redirect(conn, to: Routes.user_lobby_path(conn, :index, user.id))
  end
end
