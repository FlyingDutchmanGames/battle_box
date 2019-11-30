defmodule BattleBoxWeb.CounterLive do
  use Phoenix.LiveView

  def mount(_session, socket) do
    {:ok, assign(socket, :counter, 0)}
  end

  def handle_event("incr", _event, socket) do
    {:noreply, update(socket, :counter, &(&1 + 1))}
  end

  def render(assigns) do
    ~L"""
    <script>window.useLiveView = true</script>
    <label>Counter: <%= @counter %></label><br>
    <button phx-click="incr">+</button>
    """
  end
end
