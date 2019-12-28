defmodule BattleBox.Games.RobotGame.LogicTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.{Game, Logic}
  import BattleBox.Games.RobotGame.Terrain.Helpers
  import BattleBox.Games.RobotGameTest.Helpers

  describe "spawning" do
    test "it will create robots" do
      test_terrain = ~t/2 1
                        1 2/

      game = Game.new(terrain: test_terrain, spawn_per_player: 1)

      assert length(Game.robots(game)) == 0
      game = Logic.calculate_turn(game, [])
      assert length(Game.robots(game)) == 2

      assert [{0, 0}, {1, 1}] ==
               Game.robots(game)
               |> Enum.map(&Map.get(&1, :location))
               |> Enum.sort()

      assert [:player_1, :player_2] ==
               Enum.map(Game.robots(game), &Map.get(&1, :player_id)) |> Enum.sort()
    end

    test "it will destroy an existing robot on a spawn point" do
      test_terrain = ~t/2 1
                        1 2/

      test_robots_spawn = ~g/1 0
                             0 2/

      robots =
        Game.new(terrain: test_terrain, spawn_per_player: 1)
        |> Game.put_events(test_robots_spawn)
        |> Logic.calculate_turn([])
        |> Game.robots()

      assert length(robots) == 2
      Enum.each(robots, fn robot -> refute robot.id in [1, 2] end)
    end
  end
end
