defmodule BattleBoxWeb.LogoutController do
  use BattleBoxWeb, :controller

  def logout(conn, _params) do
    conn
    |> delete_session(:user_id)
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
