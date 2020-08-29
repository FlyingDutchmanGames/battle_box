defmodule BattleBox.Games.RobotGame.Ais.StrategyTest do
  use ExUnit.Case, async: true
  import BattleBox.Games.RobotGame.Ais.Strategy.{Utilites, Moves}
  import BattleBox.Games.RobotGame.Settings.Terrain.Helpers

  @terrain ~t/1 1 1
              1 1 1
              1 1 1/

  describe "towards/2" do
    for {start, target, next_step} <- [
          {[0, 0], [0, 1], [0, 1]},
          {[0, 0], [0, 2], [0, 1]},
          {[0, 0], [1, 0], [1, 0]},
          {[0, 0], [2, 0], [1, 0]},
          {[0, 0], [0, 0], [0, 0]},
          {[0, 0], [1_000, 1_000], [0, 0]}
        ] do
      test "towards(#{inspect(start)}, #{inspect(target)}, @terrain) => #{inspect(next_step)}" do
        assert towards(unquote(start), unquote(target), @terrain) == unquote(next_step)
      end
    end
  end

  describe "manhattan_distance/2" do
    test "You can pass robots to it" do
      assert manhattan_distance(%{location: [0, 0]}, %{location: [3, 4]}) == 5.0
    end
  end

  describe "moves" do
    test "generate the correct moves" do
      assert guard(%{id: 1}) == %{"type" => "guard", "robot_id" => 1}
      assert explode(%{id: 1}) == %{"type" => "explode", "robot_id" => 1}
      assert move(%{id: 1}, [1, 2]) == %{"type" => "move", "robot_id" => 1, "target" => [1, 2]}

      assert attack(%{id: 1}, [1, 2]) == %{
               "type" => "attack",
               "robot_id" => 1,
               "target" => [1, 2]
             }

      assert attack(%{id: 1}, %{location: [1, 2]}) == %{
               "type" => "attack",
               "robot_id" => 1,
               "target" => [1, 2]
             }
    end
  end
end
