defmodule BattleBoxWeb.Plugs.RequireNotBanned do
  alias BattleBox.User
  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn

  def init(_), do: :not_used

  def call(conn, _config) do
    case conn.assigns.current_user do
      %User{is_banned: false} -> conn
      _ -> conn |> redirect(to: "/banned") |> halt()
    end
  end
end
