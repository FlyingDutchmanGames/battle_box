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

      %{pid: pid} = connection ->
        Process.monitor(pid)
        {:ok, assign(socket, connection: connection, connected?: connected?(socket)), temporary_assigns: [messages: []]}
    end
  end

  def render(%{not_found: true}),
    do: PageView.render("not_found.html", message: "Connection not found")

  def render(assigns) do
    ConnectionView.render("debug.html", assigns)
  end

  def handle_info({type, _connection_id, message}, socket) when type in [:got_message, :sent_to_socket] do
    {:noreply, assign(socket, messages: [%{id: Ecto.UUID.generate(), type: type, message: message}])}
  end

  def get_connection(connection_id) do
    GameEngine.get_connection(game_engine(), connection_id)
  end
end
