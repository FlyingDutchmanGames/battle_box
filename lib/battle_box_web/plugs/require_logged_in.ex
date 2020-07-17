defmodule BattleBoxWeb.Plugs.RequireLoggedIn do
  alias BattleBox.User
  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn

  def init(_), do: :not_used

  def call(conn, _config) do
    case conn.assigns.current_user do
      %User{} ->
        conn

      nil ->
        conn
        |> redirect(to: "/login")
        |> halt()
    end
  end
end
