defmodule BattleBox.Games.RobotGame.LogicTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.{Logic, Game}

  describe "spawning_round?/1" do
    test "it knows if its a spawning round based on the turn and spawn_every param" do
      should_spawn = [
        # Spawn when the turn is a multiple of the 'spawn_every' setting
        %{turn: 10, spawn_every: 1},
        %{turn: 10, spawn_every: 2},
        %{turn: 10, spawn_every: 5},
        %{turn: 10, spawn_every: 10},
        %{turn: 20, spawn_every: 10},
        # Always spawn on the first (0th) turn
        %{turn: 0, spawn_every: 1},
        %{turn: 0, spawn_every: 2},
        %{turn: 0, spawn_every: 12_323_123_123}
      ]

      Enum.each(should_spawn, fn %{turn: turn, spawn_every: spawn_every} ->
        assert Logic.spawning_round?(game_with_turn_and_spawn_every(turn, spawn_every))
      end)

      should_not_spawn = [
        %{turn: 10, spawn_every: 3},
        %{turn: 10, spawn_every: 14},
        %{turn: 10, spawn_every: 20}
      ]

      Enum.each(should_not_spawn, fn %{turn: turn, spawn_every: spawn_every} ->
        refute Logic.spawning_round?(game_with_turn_and_spawn_every(turn, spawn_every))
      end)
    end
  end

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

      existing_robots = [
        %{robot_id: "DESTROY_ME_1", location: {0, 0}},
        %{robot_id: "DESTROY_ME_2", location: {1, 1}}
      ]

      game =
        Game.new()
        |> put_in([:terrain], test_terrain)
        |> put_in([:settings, :spawn_per_player], 1)
        |> put_in([:robots], existing_robots)

      game = Logic.apply_spawn(game)

      Enum.each(game.robots, fn robot ->
        refute robot.robot_id in ["DESTROY_ME_1", "DESTROY_ME_2"]
      end)
    end
  end

  defp game_with_turn_and_spawn_every(turn, spawn_every) do
    Game.new()
    |> put_in([:settings, :spawn_every], spawn_every)
    |> put_in([:turn], turn)
  end
end
