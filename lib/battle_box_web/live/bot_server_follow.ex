defmodule BattleBoxWeb.BotServerFollow do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.BotView

  # alias BattleBox.{GameEngine, User, Bot, Repo}

  def render(assigns) do
    BotView.render("follow.html", assigns)
  end
end
