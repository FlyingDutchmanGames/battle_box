defmodule BattleBoxWeb.Plugs.RequireAdmin do
  alias BattleBox.User
  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn

  def init(_), do: :not_used

  def call(conn, _config) do
    case conn.assigns.current_user do
      %User{is_admin: true} -> conn
      _ -> conn |> redirect(to: "/") |> halt()
    end
  end
end
