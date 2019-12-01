defmodule BattleBox.Games.RobotGame.GameTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.{Game, Terrain}

  test "it has the correct defaults" do
    correct_defaults = %{
      settings: %{
        spawn_every: 10,
        spawn_per_player: 5,
        robot_hp: 50,
        attack_range: %{min: 8, max: 10},
        collision_damage: 5,
        suicide_damage: 15,
        max_turns: 100
      },
      robots: [],
      turn: 0,
      terrain: Terrain.default(),
      players: ["player_1", "player_2"]
    }

    assert correct_defaults == Game.new()
  end

  describe "add_robot/2" do
    test "add_robot will add a robot and append hp and robot id" do
      game =
        Game.new()
        |> put_in([:settings, :robot_hp], 42)

      assert Game.robots(game) == []
      robot = %{player_id: "TEST_PLAYER", location: {1, 1}}
      game = Game.add_robot(game, robot)

      assert [
               %{
                 robot_id: robot_id,
                 hp: 42,
                 player_id: "TEST_PLAYER",
                 location: {1, 1}
               }
             ] = Game.robots(game)

      assert <<_::size(288)>> = robot_id
    end

    test "allows for overriding the robot_id and hp" do
      game = Game.new()
      robot = %{player_id: "TEST_PLAYER", location: {1, 1}, robot_id: "TEST_ROBOT_ID", hp: 999}
      game = Game.add_robot(game, robot)

      assert [
               %{
                 robot_id: "TEST_ROBOT_ID",
                 hp: 999,
                 player_id: "TEST_PLAYER",
                 location: {1, 1}
               }
             ] = Game.robots(game)
    end

    test "add_robots/2 allows you to add multiple robots" do
      game = Game.new()

      robots = [
        %{player_id: "TEST_PLAYER", location: {1, 1}},
        %{player_id: "TEST_PLAYER_2", location: {2, 2}}
      ]

      game = Game.add_robots(game, robots)
      assert length(Game.robots(game)) == 2
    end
  end

  describe "remove_robot" do
    test "you can remove a robot" do
      game = Game.new()

      robot = %{player_id: "TEST_PLAYER", location: {1, 1}, robot_id: "TEST_ROBOT_ID"}

      game = Game.add_robot(game, robot)
      assert length(Game.robots(game)) == 1
      game = Game.remove_robot(game, robot)
      assert length(Game.robots(game)) == 0
    end

    test "you can remove a robot by an id" do
      game = Game.new()

      robot = %{player_id: "TEST_PLAYER", location: {1, 1}, robot_id: "TEST_ROBOT_ID"}

      game = Game.add_robot(game, robot)
      assert length(Game.robots(game)) == 1
      game = Game.remove_robot(game, "TEST_ROBOT_ID")
      assert length(Game.robots(game)) == 0
    end

    test "you can multiple robots" do
      game = Game.new()

      robots = [
        %{player_id: "TEST_PLAYER", location: {1, 1}},
        %{player_id: "TEST_PLAYER_2", location: {2, 2}}
      ]

      game = Game.add_robots(game, robots)
      assert length(Game.robots(game)) == 2
      game = Game.remove_robots(game, Game.robots(game))
      assert length(Game.robots(game)) == 0
    end
  end

  describe "get_robot/2" do
    test "you can get a robot by id" do
      game = Game.new()
      robot = %{player_id: "TEST_PLAYER", location: {1, 1}, robot_id: "TEST_ROBOT_ID", hp: 50}
      game = Game.add_robot(game, robot)
      assert ^robot = Game.get_robot(game, "TEST_ROBOT_ID")
    end

    test "trying to get a robot by id that doesn't exist gives `nil`" do
      game = Game.new()
      assert nil == Game.get_robot(game, "TEST_ROBOT_ID")
    end
  end

  describe "get_attack_damage" do
    test "you can get an attack damage" do
      game = Game.new()

      1..100
      |> Enum.each(fn _ ->
        damage = Game.get_attack_damage(game)

        assert damage >= game.settings.attack_range.min &&
                 damage <= game.settings.attack_range.max
      end)
    end
  end

  describe "get_suicide_damage" do
    test "it gets the value set in settings" do
      game =
        Game.new()
        |> put_in([:settings, :suicide_damage], 42)

      assert 42 = Game.get_suicide_damage(game)
    end
  end

  describe "adjacent_locations/1" do
    test "it provides the adjacent locations" do
      assert [{1, 0}, {-1, 0}, {0, 1}, {0, -1}] = Game.adjacent_locations({0, 0})
    end
  end
end
