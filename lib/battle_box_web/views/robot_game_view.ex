defmodule BattleBoxWeb.RobotGameView do
  use BattleBoxWeb, :view
  alias BattleBox.Games.RobotGame.Game

  def move_direction({from_row, from_col}, {to_row, to_col}) do
    case {from_row - to_row, from_col - to_col} do
      {1, 0} -> :up
      {-1, 0} -> :down
      {0, -1} -> :right
      {0, 1} -> :left
    end
  end

  def move_icon(move, robot_location) do
    case move.type do
      :attack ->
        case move_direction(robot_location, move.target) do
          :left -> "🤛"
          :right -> "🤜"
          :up -> "✊"
          :down -> "👎"
        end

      :guard ->
        "🐢"

      :move ->
        case move_direction(robot_location, move.target) do
          :left -> "⬅️"
          :right -> "➡️"
          :up -> "⬆️"
          :down -> "⬇️"
        end

      :suicide ->
        "💣"

      _ ->
        ""
    end
  end

  def terrain_number(location) do
    case location do
      [0, col] -> col
      [row, 0] -> row
      _ -> nil
    end
  end
end
