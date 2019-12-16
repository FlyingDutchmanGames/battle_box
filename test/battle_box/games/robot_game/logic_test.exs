defmodule BattleBox.Games.RobotGame.LogicTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.Game
  import BattleBox.Games.RobotGame.Logic
  import BattleBox.Games.RobotGame.Terrain.Helpers

  describe "spawning" do
    test "it will create robots" do
      test_terrain = ~t/2 1
                        1 2/

      game = Game.new(terrain: test_terrain, spawn_per_player: 1)

      assert length(Game.robots(game)) == 0
      game = calculate_turn(game, [])
      assert length(Game.robots(game)) == 2

      assert [{0, 0}, {1, 1}] ==
               Game.robots(game)
               |> Enum.map(&Map.get(&1, :location))
               |> Enum.sort()

      assert [:player_1, :player_2] ==
               Enum.map(game.robots, &Map.get(&1, :player_id)) |> Enum.sort()
    end

    test "it will destroy an existing robot on a spawn point" do
      test_terrain = ~t/2 1
                        1 2/

      robots = [
        %{player_id: :player_1, id: "DESTROY_ME_1", location: {0, 0}},
        %{player_id: :player_2, id: "DESTROY_ME_2", location: {1, 1}}
      ]

      robots =
        Game.new(terrain: test_terrain, spawn_per_player: 1)
        |> Game.add_robots(robots)
        |> calculate_turn([])
        |> Game.robots()

      assert length(robots) == 2
      Enum.each(robots, fn robot -> refute robot.id in ["DESTROY_ME_1", "DESTROY_ME_2"] end)
    end
  end
end
