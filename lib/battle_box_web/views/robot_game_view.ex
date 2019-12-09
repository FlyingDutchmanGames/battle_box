defmodule BattleBoxWeb.RobotGameView do
  use BattleBoxWeb, :view
  alias BattleBox.Games.RobotGame.Game

  def move_icon(nil), do: nil

  def move_icon(move) do
    case move.type do
      :attack -> "🔪"
      :guard -> "🐢"
      :move -> "➡️"
      :suicide -> "💣"
      _ -> ""
    end
  end
end
