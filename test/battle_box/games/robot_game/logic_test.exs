defmodule BattleBox.Games.RobotGame.LogicTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.Game
  import BattleBox.Games.RobotGame.Logic
  import BattleBox.Games.RobotGame.Terrain.Helpers

  describe "apply_spawn/1" do
    test "it will create robots" do
      test_terrain = ~t/2 1
                        1 2/

      game = Game.new(terrain: test_terrain, spawn_per_player: 1)

      assert length(Game.robots(game)) == 0
      game = apply_spawn(game)
      assert length(Game.robots(game)) == 2

      assert [{0, 0}, {1, 1}] ==
               Game.robots(game)
               |> Enum.map(&Map.get(&1, :location))
               |> Enum.sort()

      assert game.players == Enum.map(game.robots, &Map.get(&1, :player_id)) |> Enum.sort()
    end

    test "it will destroy an existing robot on a spawn point" do
      test_terrain = ~t/2 1
                        1 2/

      robots = [
        %{player_id: "1", id: "DESTROY_ME_1", location: {0, 0}},
        %{player_id: "2", id: "DESTROY_ME_2", location: {1, 1}}
      ]

      robots =
        Game.new(terrain: test_terrain, spawn_per_player: 1)
        |> Game.add_robots(robots)
        |> apply_spawn()
        |> Game.robots()

      assert length(robots) == 2
      Enum.each(robots, fn robot -> refute robot.id in ["DESTROY_ME_1", "DESTROY_ME_2"] end)
    end
  end
end
