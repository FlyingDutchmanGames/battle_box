defmodule BattleBox.Utilities.Graph.AStarTest do
  use ExUnit.Case, async: true

  import BattleBox.Utilities.{Graph.AStar, Grid}

  describe "a_star" do
    test "When the start and end locations are the same" do
      assert {:ok, [:a]} == a_star(:a, :a, fn _node -> [] end, fn _from, _to -> 1 end)
    end

    test "When there is no path it returns an error" do
      assert {:error, :no_path} ==
               a_star(:a, :b, fn _node -> [] end, fn _from, _to -> 1 end)
    end

    test "It can route on a map" do
      assert {:ok, [:a, :b, :c]} ==
               a_star(
                 :a,
                 :c,
                 fn
                   :a -> [:b]
                   :b -> [:c]
                 end,
                 fn _from, _to -> 1 end
               )
    end

    test "It can handle when there are multiple paths and find the shortest" do
      assert {:ok, [[0, 0], [0, 1], [1, 1]]} ==
               a_star(
                 [0, 0],
                 [1, 1],
                 fn
                   [0, 0] -> [[0, 1], [1, 0]]
                   [0, 1] -> [[1, 1]]
                   [1, 0] -> [[1, 1]]
                 end,
                 &manhattan_distance/2
               )
    end

    test "It can handle when a graph is bidirection" do
      assert {:ok, [[0, 0], [0, 1], [1, 1]]} ==
               a_star(
                 [0, 0],
                 [1, 1],
                 fn
                   [0, 0] -> [[0, 1], [1, 0]]
                   [0, 1] -> [[1, 1], [0, 0]]
                   [1, 0] -> [[1, 1], [0, 0]]
                   [1, 1] -> [[1, 0], [0, 1]]
                 end,
                 &manhattan_distance/2
               )
    end

    test "It will run out of iterations" do
      assert {:error, :iterations_exceeded} ==
               a_star(
                 [0, 0],
                 [1_000_000, 1_000_000],
                 fn [x, y] -> [[x + 1, y]] end,
                 &manhattan_distance/2
               )
    end
  end
end
