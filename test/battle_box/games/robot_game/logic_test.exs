defmodule BattleBox.Games.RobotGame.LogicTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.Game
  import BattleBox.Games.RobotGame.Logic

  describe "apply_spawn/1" do
    test "it will create robots" do
      test_terrain = %{
        {0, 0} => :spawn,
        {1, 1} => :spawn
      }

      game = Game.new(%{terrain: test_terrain, settings: %{spawn_per_player: 1}})

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
      test_terrain = %{
        {0, 0} => :spawn,
        {1, 1} => :spawn
      }

      robots = [
        %{player_id: "1", robot_id: "DESTROY_ME_1", location: {0, 0}},
        %{player_id: "2", robot_id: "DESTROY_ME_2", location: {1, 1}}
      ]

      Game.new(%{terrain: test_terrain, settings: %{spawn_per_player: 1}})
      |> Game.add_robots(robots)
      |> apply_spawn()
      |> Game.robots()
      |> Enum.each(fn robot ->
        refute robot.robot_id in ["DESTROY_ME_1", "DESTROY_ME_2"]
      end)
    end
  end

  describe "apply_movement/5" do
    test "you can move into a normal space" do
      terrain = %{{0, 0} => :normal, {0, 1} => :normal}

      assert %{location: {0, 1}} =
               Game.new(%{spawn?: false, terrain: terrain})
               |> Game.add_robot(%{player_id: "player_1", robot_id: "TEST", location: {0, 0}})
               |> apply_movement(
                 "TEST",
                 {0, 1},
                 [%{robot_id: "TEST", type: :move, target: {0, 1}}],
                 []
               )
               |> Game.get_robot("TEST")
    end

    test "you cannot move into an inaccessible space (and will get collison damage)" do
      terrain = %{{0, 0} => :normal, {0, 1} => :inaccessible}

      assert %{location: {0, 0}, hp: 45} =
               Game.new(%{spawn?: false, terrain: terrain})
               |> Game.add_robot(%{player_id: "player_1", robot_id: "TEST", location: {0, 0}})
               |> apply_movement(
                 "TEST",
                 {0, 1},
                 [%{robot_id: "TEST", type: :move, target: {0, 1}}],
                 []
               )
               |> Game.get_robot("TEST")
    end

    test "you cannot move into a space with another robot (you will get collison damage)" do
      terrain = %{{0, 0} => :normal, {0, 1} => :normal}

      after_move =
        Game.new(%{spawn?: false, terrain: terrain})
        |> Game.add_robots([
          %{player_id: "player_1", robot_id: "TEST", location: {0, 0}},
          %{player_id: "player_1", robot_id: "IN_SPACE", location: {0, 1}}
        ])
        |> apply_movement("TEST", {0, 1}, [%{robot_id: "TEST", type: :move, target: {0, 1}}], [])

      assert %{location: {0, 0}, hp: 45} = Game.get_robot(after_move, "TEST")
      assert %{location: {0, 1}, hp: 45} = Game.get_robot(after_move, "IN_SPACE")
    end

    test "if you try to move into a guarded space, you don't move, you take damage, and the other robot doesn't" do
      terrain = %{{0, 0} => :normal, {0, 1} => :normal}

      after_move =
        Game.new(%{spawn?: false, terrain: terrain})
        |> Game.add_robots([
          %{player_id: "player_1", robot_id: "TEST", location: {0, 0}},
          %{player_id: "player_1", robot_id: "IN_SPACE", location: {0, 1}}
        ])
        |> apply_movement("TEST", {0, 1}, [%{robot_id: "TEST", type: :move, target: {0, 1}}], [
          {0, 1}
        ])

      assert %{location: {0, 0}, hp: 45} = Game.get_robot(after_move, "TEST")
      assert %{location: {0, 1}, hp: 50} = Game.get_robot(after_move, "IN_SPACE")
    end
  end

  describe "apply_attack/3" do
    test "An attack on an empty square is a noop" do
      game = Game.new()
      assert ^game = apply_attack(game, {0, 0}, [])
    end

    test "An attack on an unguarded location yields full damage" do
      robot_location = {0, 0}
      robot = %{location: robot_location, player_id: "1", hp: 50, robot_id: "TEST"}

      assert %{hp: 0} =
               Game.new(%{settings: %{attack_range: %{min: 50, max: 50}}})
               |> Game.add_robot(robot)
               |> apply_attack(robot_location, [])
               |> Game.get_robot("TEST")
    end

    test "An attack on a guarded location yields half damage" do
      robot_location = {0, 0}
      robot = %{location: robot_location, player_id: "1", hp: 50, robot_id: "TEST"}

      assert %{hp: 25} =
               Game.new(%{settings: %{attack_range: %{min: 50, max: 50}}})
               |> Game.add_robot(robot)
               |> apply_attack(robot_location, [robot_location])
               |> Game.get_robot("TEST")
    end
  end

  describe "apply_suicide" do
    test "suicide on an empty board is a noop" do
      game = Game.new()
      assert ^game = apply_suicide(game, {0, 0}, [])
    end

    test "suicide inflicts damage on adjacent robots" do
      suicide_robot_location = {1, 1}
      other_robot_locations = [{2, 1}, {0, 1}, {1, 2}, {1, 0}]

      robots =
        other_robot_locations
        |> Enum.map(&%{player_id: "1", hp: 50, location: &1})

      assert [%{hp: 0}, %{hp: 0}, %{hp: 0}, %{hp: 0}] =
               Game.new(%{settings: %{suicide_damage: 50}})
               |> Game.add_robots(robots)
               |> apply_suicide(suicide_robot_location, [])
               |> Game.robots()
    end

    test "suicide in guarded locations yields half damage" do
      suicide_robot_location = {1, 1}
      other_robot_locations = [{2, 1}, {0, 1}, {1, 2}, {1, 0}]

      robots =
        other_robot_locations
        |> Enum.map(&%{player_id: "1", hp: 50, location: &1})

      assert [%{hp: 25}, %{hp: 25}, %{hp: 25}, %{hp: 25}] =
               Game.new(%{settings: %{suicide_damage: 50}})
               |> Game.add_robots(robots)
               |> apply_suicide(suicide_robot_location, other_robot_locations)
               |> Game.robots()
    end
  end
end
