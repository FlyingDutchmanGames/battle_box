defmodule BattleBoxWeb.ConnectionAuthorizationsController do
  use BattleBoxWeb, :controller

  def new(conn, %{"connection_id" => connection_id}) do
    render(conn, "new.html")
  end

  def create(conn, %{"connection_id" => connection_id}) do
  end
end
