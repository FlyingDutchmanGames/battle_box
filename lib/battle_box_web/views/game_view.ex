defmodule BattleBoxWeb.GameView do
  use BattleBoxWeb, :view
  alias BattleBoxWeb.Live.{FollowBack, GameViewer}
  alias BattleBoxWeb.PageView
  alias BattleBox.Game

  def adjacent_turns(turn) do
    case turn do
      turn when turn < 4 -> 1..7
      turn -> (turn - 3)..(turn + 3)
    end
  end
end
