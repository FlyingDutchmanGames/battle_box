defmodule BattleBoxWeb.Live.HumanPlayer do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.HumanView

  def render(assigns) do
    HumanView.render("_human_player.html", assigns)
  end
end
