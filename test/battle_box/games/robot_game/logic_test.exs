defmodule BattleBox.Games.RobotGame.LogicTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.{Logic, Game}

  describe "apply_spawn/1" do
    test "it will create robots" do
      test_terrain = %{
        {0, 0} => :spawn,
        {1, 1} => :spawn
      }

      game =
        Game.new()
        |> put_in([:terrain], test_terrain)
        |> put_in([:settings, :spawn_per_player], 1)

      assert length(game.robots) == 0
      game = Logic.apply_spawn(game)
      assert length(game.robots) == 2

      assert [{0, 0}, {1, 1}] ==
               game.robots
               |> Enum.map(&Map.get(&1, :location))
               |> Enum.sort()

      assert game.players == Enum.map(game.robots, &Map.get(&1, :player_id)) |> Enum.sort()
    end

    test "it will destroy an existing robot on a spawn point" do
      test_terrain = %{
        {0, 0} => :spawn,
        {1, 1} => :spawn
      }

      robots = [
        %{player_id: "1", robot_id: "DESTROY_ME_1", location: {0, 0}},
        %{player_id: "2", robot_id: "DESTROY_ME_2", location: {1, 1}}
      ]

      game =
        Game.new()
        |> put_in([:terrain], test_terrain)
        |> put_in([:settings, :spawn_per_player], 1)
        |> Game.add_robots(robots)

      game = Logic.apply_spawn(game)

      Enum.each(Game.robots(game), fn robot ->
        refute robot.robot_id in ["DESTROY_ME_1", "DESTROY_ME_2"]
      end)
    end
  end

  describe "apply_attack" do
    test "An attack on an empty square is a noop" do
      robots = [
        %{player_id: "1", location: {0, 0}},
        %{player_id: "2", location: {1, 1}}
      ]

      game =
        Game.new()
        |> Game.add_robots(robots)

      raise "NOT FINISHED"
    end

    test "An attack on a guarded location yields half damage"
  end

  describe "apply_suicide" do
  end
end
