defmodule BattleBoxWeb.ConnectionDebugger do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.{ConnectionView, PageView}
  alias BattleBox.GameEngine

  def mount(%{"connection_id" => connection_id}, session, socket) do
    if connected?(socket) do
      GameEngine.subscribe(game_engine(), "connection-debugger:#{connection_id}")
    end

    case get_connection(connection_id) do
      nil ->
        {:ok, assign(socket, :not_found, true)}

      connection ->
        {:ok, assign(socket, connection: connection), temporary_assigns: [debug_messages: []]}
    end
  end

  def render(%{not_found: true}),
    do: PageView.render("not_found.html", message: "Connection not found")

  def render(assigns) do
    ConnectionView.render("debug.html", assigns)
  end

  def get_connection(connection_id) do
    GameEngine.get_connection(game_engine(), connection_id)
    |> IO.inspect(label: "CONNECTION")
  end
end
