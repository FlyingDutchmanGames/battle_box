defmodule BattleBoxWeb.Live.Games.Marooned do
  use BattleBoxWeb, :live_component
  alias BattleBoxWeb.MaroonedView

  def preload(assigns) do
    assigns
  end

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    MaroonedView.render("_play.html", assigns)
  end
end
