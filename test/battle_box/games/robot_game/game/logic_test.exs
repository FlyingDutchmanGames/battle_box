defmodule BattleBox.Games.RobotGame.LogicTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.{RobotGame, RobotGame.Logic}
  import BattleBox.Games.RobotGame.Settings.Terrain.Helpers
  import BattleBox.Games.RobotGameTest.Helpers

  describe "spawning" do
    test "it will create robots" do
      test_terrain = ~t/2 1
                        1 2/

      game = RobotGame.new(settings: %{terrain: test_terrain, spawn_per_player: 1})

      assert length(RobotGame.robots(game)) == 0
      game = Logic.calculate_turn(game, %{"player_1" => [], "player_2" => []})
      assert length(RobotGame.robots(game)) == 2

      assert [[0, 0], [1, 1]] ==
               RobotGame.robots(game)
               |> Enum.map(&Map.get(&1, :location))
               |> Enum.sort()

      assert ["player_1", "player_2"] ==
               Enum.map(RobotGame.robots(game), &Map.get(&1, :player_id)) |> Enum.sort()

      assert 2 ==
               RobotGame.robots(game)
               |> Enum.map(&Map.get(&1, :id))
               |> Enum.uniq()
               |> length
    end

    test "it will destroy an existing robot on a spawn point" do
      test_terrain = ~t/2 1
                        1 2/

      test_robots_spawn = ~g/1 0
                             0 2/

      robots =
        RobotGame.new(settings: %{terrain: test_terrain, spawn_per_player: 1})
        |> RobotGame.put_events(test_robots_spawn)
        |> Logic.calculate_turn(%{"player_1" => [], "player_2" => []})
        |> RobotGame.robots()

      assert length(robots) == 2
      Enum.each(robots, fn robot -> refute robot.id in [100, 200] end)
    end
  end
end
