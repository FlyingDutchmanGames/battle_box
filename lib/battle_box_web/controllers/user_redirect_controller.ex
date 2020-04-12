defmodule BattleBoxWeb.UserRedirectController do
  use BattleBoxWeb, :controller

  def lobbies(%{assigns: %{user: user}} = conn, _params) do
    redirect(conn, to: Routes.user_lobby_path(conn, :index, user.id))
  end

  def bots(%{assigns: %{user: user}} = conn, _params) do
    redirect(conn, to: Routes.live_path(conn, BattleBoxWeb.Bots, user.id))
  end

  def users(%{assigns: %{user: user}} = conn, _params) do
    redirect(conn, to: Routes.user_path(conn, :show, user.id))
  end
end
