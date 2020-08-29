defmodule BattleBox.Utilities.GridTest do
  use ExUnit.Case, async: true

  alias BattleBox.Utilities.Grid

  describe "manhattan_distance/2" do
    for {point_a, point_b, distance} <- [
          {[0, 0], [0, 0], 0.0},
          {[0, 0], [0, 1], 1.0},
          {[1, 0], [0, 0], 1.0},
          {[0, 0], [0, -1], 1.0},
          {[0, 0], [3, 4], 5.0}
        ] do
      test "manhattan_distance(#{inspect(point_a)}, #{inspect(point_b)}) => #{inspect(distance)}" do
        assert Grid.manhattan_distance(unquote(point_a), unquote(point_b)) == unquote(distance)
      end
    end
  end
end
