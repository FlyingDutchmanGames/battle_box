defmodule BattleBox.Utilities.GridTest do
  use ExUnit.Case, async: true

  alias BattleBox.Utilities.Grid

  describe "manhattan_distance/2" do
    test "it gives the manhattan_distance between two points" do
      assert Grid.manhattan_distance([0, 0], [0, 0]) == 0.0
      assert Grid.manhattan_distance([0, 0], [0, 1]) == 1.0
      assert Grid.manhattan_distance([0, 0], [0, -1]) == 1.0
      assert Grid.manhattan_distance([0, 0], [3, 4]) == 5.0
    end
  end
end
