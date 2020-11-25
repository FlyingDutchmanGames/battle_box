defmodule BattleBoxWeb.Live.Games.Marooned do
  use BattleBoxWeb, :live_component
  alias BattleBoxWeb.MaroonedView

  def preload(assigns) do
    assigns
  end

  def mount(socket) do
    {:ok, assign(socket, move_to: nil, remove: nil)}
  end

  def handle_event("select-move", %{"x" => x, "y" => y}, socket) do
    x = String.to_integer(x)
    y = String.to_integer(y)
    {:noreply, assign(socket, move_to: [x, y])}
  end

  def handle_event("select-remove", %{"x" => x, "y" => y}, socket) do
    x = String.to_integer(x)
    y = String.to_integer(y)
    {:noreply, assign(socket, remove: [x, y])}
  end

  def handle_event("submit", _, socket) do
    send(
      self(),
      {:commands, %{"remove" => socket.assigns.remove, "to" => socket.assigns.move_to}}
    )

    {:noreply, socket}
  end

  def handle_event("reset", _, socket) do
    {:noreply, assign(socket, move_to: nil, remove: nil)}
  end

  def render(assigns) do
    MaroonedView.render("_play.html", assigns)
  end
end
