defmodule BattleBoxWeb.LoginController do
  use BattleBoxWeb, :controller
  alias Assent.Strategy.Github

  def github_login(conn, _params) do
    # redirect(conn, external: url)
  end

  def github_callback(conn, params) do
    # Authorize
    conn
    |> redirect(to: "/")
  end

  defp config do
    Application.fetch_env!(:battle_box, :github)
  end
end
