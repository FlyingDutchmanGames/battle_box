defmodule BattleBox.Games.RobotGame.GameMapTest do
  use ExUnit.Case
  alias BattleBox.Games.RobotGame.GameMap

  describe "default" do
    test "it has the correct number of spaces" do
      map = GameMap.default()
      assert length(Enum.into(map.terrain, [])) == 361
    end

    test "all the spaces are represented" do
      map = GameMap.default()

      expected_positions = for row <- 0..18, col <- 0..18, do: {row, col}
      actual_positions = Map.keys(map.terrain)

      assert Enum.sort(expected_positions) == Enum.sort(actual_positions)
    end
  end
end
