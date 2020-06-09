defmodule BattleBoxWeb.GameView do
  use BattleBoxWeb, :view
  alias BattleBoxWeb.Live.{FollowBack, GameViewer}
  alias BattleBoxWeb.PageView
  alias BattleBox.Game

  def adjacent_turns(turn, max_turn) do
    case turn do
      turn when turn < 4 -> 1..7
      turn when turn + 3 < max_turn -> (turn - 3)..(turn + 3)
      turn when turn + 3 >= max_turn -> (max_turn - 7)..max_turn
    end
  end
end
