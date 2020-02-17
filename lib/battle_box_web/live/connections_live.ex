defmodule BattleBoxWeb.ConnectionsLive do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.{ConnectionsView, PageView}
  alias BattleBox.{GameEngine, User}

  @refresh_rate_ms 1000

  def mount(%{"user_id" => user_id}, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(@refresh_rate_ms, :refresh)
    end

    case User.get_by_id(user_id) do
      %User{} = user ->
        {:ok, assign(socket, user: user, connections: get_connections(user.id))}

      nil ->
        {:ok, assign(socket, not_found: true)}
    end
  end

  def mount(_params, %{"user_id" => user_id}, socket) do
    {:ok, push_redirect(socket, to: Routes.live_path(@endpoint, __MODULE__, user_id))}
  end

  def render(%{not_found: true}) do
    PageView.render("not_found.html", message: "User not found")
  end

  def render(assigns) do
    ConnectionsView.render("connections.html", assigns)
  end

  def handle_event("kill_connection_" <> connection_id, _, socket) do
    %{pid: pid} = GameEngine.get_connection(game_engine(), connection_id)
    Process.exit(pid, :kill)
    {:noreply, socket}
  end

  def handle_info(:refresh, socket) do
    {:noreply, assign(socket, :connections, get_connections(socket.assigns.user.id))}
  end

  def get_connections(user_id) do
    GameEngine.get_connections_with_user_id(game_engine(), user_id)
  end
end
