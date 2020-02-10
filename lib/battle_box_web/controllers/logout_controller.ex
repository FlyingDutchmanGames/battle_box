defmodule BattleBoxWeb.LogoutController do
  use BattleBoxWeb, :controller
  alias BattleBox.User

  def logout(conn, params) do
    conn
    |> delete_session(:user_id)
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
