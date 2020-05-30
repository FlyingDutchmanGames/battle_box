defmodule BattleBoxWeb.UserRedirectController do
  use BattleBoxWeb, :controller

  def lobbies(%{assigns: %{current_user: user}} = conn, _params) do
    redirect(conn, to: Routes.user_lobby_path(conn, :index, user.username))
  end

  def bots(%{assigns: %{current_user: user}} = conn, _params) do
    redirect(conn, to: Routes.live_path(conn, BattleBoxWeb.Bots, user.username))
  end

  def users(%{assigns: %{current_user: user}} = conn, _params) do
    redirect(conn, to: Routes.user_path(conn, :show, user.username))
  end
end
