defmodule BattleBoxWeb.UserRedirectController do
  use BattleBoxWeb, :controller

  def arenas(%{assigns: %{current_user: user}} = conn, _params) do
    redirect(conn, to: Routes.user_arena_path(conn, :index, user.username))
  end

  def bots(%{assigns: %{current_user: user}} = conn, _params) do
    redirect(conn, to: Routes.user_bot_path(conn, :index, user.username))
  end

  def users(%{assigns: %{current_user: user}} = conn, _params) do
    redirect(conn, to: Routes.user_path(conn, :show, user.username))
  end
end
