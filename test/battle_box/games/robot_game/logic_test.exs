defmodule BattleBox.Games.RobotGame.LogicTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.{RobotGame, RobotGame.Logic}
  import BattleBox.Games.RobotGame.Settings.Terrain.Helpers
  import BattleBox.Games.RobotGameTest.Helpers

  @test_terrain ~t/2 1
                   1 2/

  describe "spawning" do
    test "it will create robots" do
      game = RobotGame.new(settings: %{terrain: @test_terrain, spawn_per_player: 1})

      assert length(RobotGame.robots(game)) == 0
      game = Logic.calculate_turn(game, %{1 => [], 2 => []})
      assert length(RobotGame.robots(game)) == 2

      assert [[0, 0], [1, 1]] ==
               RobotGame.robots(game)
               |> Enum.map(&Map.get(&1, :location))
               |> Enum.sort()

      assert [1, 2] ==
               Enum.map(RobotGame.robots(game), &Map.get(&1, :player_id)) |> Enum.sort()

      assert 2 ==
               RobotGame.robots(game)
               |> Enum.map(&Map.get(&1, :id))
               |> Enum.uniq()
               |> length
    end

    test "it will destroy an existing robot on a spawn point" do
      test_robots_spawn = ~g/0 2
                             1 0/

      robots =
        RobotGame.new(settings: %{terrain: @test_terrain, spawn_per_player: 1})
        |> RobotGame.put_events(test_robots_spawn)
        |> Logic.calculate_turn(%{1 => [], 2 => []})
        |> RobotGame.robots()

      assert length(robots) == 2
      Enum.each(robots, fn robot -> refute robot.id in [100, 200] end)
    end
  end

  describe "move" do
    test "You can move (to an adjacent square)" do
      test_robots_spawn = ~g/0 0
                             1 0/

      assert [%{id: 100, location: [0, 1]}] =
               RobotGame.new(settings: %{terrain: @test_terrain}, spawn_enabled: false)
               |> RobotGame.put_events(test_robots_spawn)
               |> Logic.calculate_turn(%{
                 1 => [%{"type" => "move", "robot_id" => 100, "target" => [0, 1]}],
                 2 => []
               })
               |> RobotGame.robots()
    end

    test "You can not move to a non adjacent square" do
      test_robots_spawn = ~g/0 0
                             1 0/

      assert [%{id: 100, location: [0, 0]}] =
               RobotGame.new(settings: %{terrain: @test_terrain}, spawn_enabled: false)
               |> RobotGame.put_events(test_robots_spawn)
               |> Logic.calculate_turn(%{
                 1 => [%{"type" => "move", "robot_id" => 100, "target" => [1, 1]}],
                 2 => []
               })
               |> RobotGame.robots()
    end
  end
end
