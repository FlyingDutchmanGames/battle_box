defmodule BattleBoxWeb.UserRedirectController do
  use BattleBoxWeb, :controller

  def lobbies(%{assigns: %{user: user}} = conn, _params) do
    redirect(conn, to: Routes.user_lobby_path(conn, :index, user.github_login_name))
  end

  def bots(%{assigns: %{user: user}} = conn, _params) do
    redirect(conn, to: Routes.live_path(conn, BattleBoxWeb.Bots, user.github_login_name))
  end

  def users(%{assigns: %{user: user}} = conn, _params) do
    redirect(conn, to: Routes.user_path(conn, :show, user.github_login_name))
  end
end
