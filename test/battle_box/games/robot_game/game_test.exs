defmodule BattleBox.Games.RobotGame.GameTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.{Game, Terrain, Robot}
  import BattleBox.Games.RobotGame.Terrain.Helpers

  describe "new/1" do
    test "it has the correct defaults" do
      correct_defaults = %Game{
        spawn_every: 10,
        spawn_per_player: 5,
        robot_hp: 50,
        attack_damage: %{min: 8, max: 10},
        collision_damage: 5,
        suicide_damage: 15,
        max_turns: 100,
        robots: [],
        turn: 0,
        terrain: Terrain.default(),
        player_1: nil,
        player_2: nil,
        spawn?: true
      }

      assert correct_defaults == Game.new()
    end

    test "you can override any top level key" do
      assert %{turn: 42} = Game.new(turn: 42)
      assert %{suicide_damage: 15, robot_hp: 42} = Game.new(suicide_damage: 15, robot_hp: 42)
    end
  end

  describe "user/2" do
    test "you can get the user for a player and it defaults to `Player 1` and `Player 2`" do
      assert "FIRST" == Game.user(Game.new(player_1: "FIRST"), :player_1)
      assert "SECOND" == Game.user(Game.new(player_2: "SECOND"), :player_2)
      assert "Player 1" == Game.user(Game.new(), :player_1)
      assert "Player 2" == Game.user(Game.new(), :player_2)
    end
  end

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

      Enum.each(should_spawn, fn settings ->
        assert Game.spawning_round?(Game.new(settings))
      end)

      should_not_spawn = [
        %{turn: 10, spawn_every: 3},
        %{turn: 10, spawn_every: 14},
        %{turn: 10, spawn_every: 20}
      ]

      Enum.each(should_not_spawn, fn settings ->
        refute Game.spawning_round?(Game.new(settings))
      end)
    end

    test "spawn?: false is never a spawning round" do
      refute Game.spawning_round?(Game.new(spawn?: false, spawn_every: 10, turn: 10))
    end
  end

  describe "score" do
    test "the score for a non existant player is 0" do
      assert 0 = Game.score(Game.new(), :player_1)
    end

    test "A player with robots is the the number of robots" do
      game =
        Game.new()
        |> Game.add_robot(%{player_id: :player_1, location: {0, 0}})

      assert 1 == Game.score(game, :player_1)
      assert 0 == Game.score(game, :player_2)
    end
  end

  describe "get_robot_at_location/2" do
    test "it gives nil if there isn't a robot at that location" do
      assert nil == Game.get_robot_at_location(Game.new(), {0, 0})
    end

    test "it can give back a robot if there is one at a location" do
      robot = %{player_id: :player_1, id: "TEST", location: {0, 0}, hp: 42}

      assert Robot.new(robot) ==
               Game.add_robot(Game.new(), robot)
               |> Game.get_robot_at_location({0, 0})
    end
  end

  describe "move_robot/3" do
    test "trying to move a robot that doesn't exist is a noop" do
      game = Game.new()
      assert ^game = Game.move_robot(game, "DOES_NOT_EXIST", {42, 42})
    end

    test "you can move a robot" do
      assert [%{location: {42, 42}}] =
               Game.new()
               |> Game.add_robot(%{player_id: :player_1, id: "TEST", location: {0, 0}})
               |> Game.move_robot("TEST", {42, 42})
               |> Game.robots()
    end
  end

  describe "add_robot/2" do
    test "add_robot will add a robot and append hp and robot id" do
      game = Game.new(robot_hp: 42)

      assert Game.robots(game) == []
      robot = %{player_id: :player_1, location: {1, 1}}
      game = Game.add_robot(game, robot)

      assert [
               %{
                 id: robot_id,
                 hp: 42,
                 player_id: :player_1,
                 location: {1, 1}
               }
             ] = Game.robots(game)

      assert <<_::size(288)>> = robot_id
    end

    test "allows for overriding the robot_id and hp" do
      game = Game.new()
      robot = %{player_id: :player_1, location: {1, 1}, id: "TEST_ROBOT_ID", hp: 999}
      game = Game.add_robot(game, robot)

      assert [
               %{
                 id: "TEST_ROBOT_ID",
                 hp: 999,
                 player_id: :player_1,
                 location: {1, 1}
               }
             ] = Game.robots(game)
    end

    test "add_robots/2 allows you to add multiple robots" do
      robots = [
        %{player_id: :player_1, location: {1, 1}},
        %{player_id: :player_1, location: {2, 2}}
      ]

      game = Game.add_robots(Game.new(), robots)
      assert length(Game.robots(game)) == 2
    end
  end

  describe "remove_robot" do
    test "you can remove a robot" do
      robot = %{player_id: :player_1, location: {1, 1}, id: "TEST_ROBOT_ID"}

      game = Game.add_robot(Game.new(), robot)
      assert length(Game.robots(game)) == 1
      game = Game.remove_robot(game, robot)
      assert length(Game.robots(game)) == 0
    end

    test "you can remove a robot by an id" do
      robot = %{player_id: :player_1, location: {1, 1}, id: "TEST_ROBOT_ID"}

      game = Game.add_robot(Game.new(), robot)
      assert length(Game.robots(game)) == 1
      game = Game.remove_robot(game, "TEST_ROBOT_ID")
      assert length(Game.robots(game)) == 0
    end

    test "you can multiple robots" do
      robots = [
        %{player_id: :player_1, location: {1, 1}},
        %{player_id: :player_2, location: {2, 2}}
      ]

      game = Game.add_robots(Game.new(), robots)
      assert length(Game.robots(game)) == 2
      game = Game.remove_robots(game, Game.robots(game))
      assert length(Game.robots(game)) == 0
    end
  end

  describe "get_robot/2" do
    test "you can get a robot by id" do
      robot = %{player_id: :player_2, location: {1, 1}, id: "TEST_ROBOT_ID", hp: 50}

      game = Game.add_robot(Game.new(), robot)
      assert Robot.new(robot) == Game.get_robot(game, "TEST_ROBOT_ID")
    end

    test "trying to get a robot by id that doesn't exist gives `nil`" do
      assert nil == Game.get_robot(Game.new(), "DOES_NOT_EXIST")
    end
  end

  describe "attack_damage" do
    test "you can get an attack damage" do
      game = Game.new()
      damage = Game.attack_damage(game)

      assert damage >= game.attack_damage.min &&
               damage <= game.attack_damage.max
    end

    test "guarded attack damage is 50% of regular damage rounding down to the integer" do
      game = Game.new(attack_damage: 100)
      assert 50 == Game.guarded_attack_damage(game)

      game = Game.new(attack_damage: 99)
      assert 49 == Game.guarded_attack_damage(game)
    end

    test "it works if the the min and max attack are the same" do
      game = Game.new(attack_damage: %{min: 50, max: 50})
      assert 50 == Game.attack_damage(game)
    end
  end

  describe "suicide_damage" do
    test "it gets the value set in settings" do
      assert 42 = Game.suicide_damage(Game.new(suicide_damage: 42))
    end

    test "guarded suicide damage is 50% of regular damage rounding down to the integer" do
      game = Game.new(suicide_damage: 10)
      assert 5 == Game.guarded_suicide_damage(game)

      game = Game.new(suicide_damage: 9)
      assert 4 == Game.guarded_suicide_damage(game)
    end
  end

  describe "adjacent_locations/1" do
    test "it provides the adjacent locations" do
      assert [{1, 0}, {-1, 0}, {0, 1}, {0, -1}] = Game.adjacent_locations({0, 0})
    end
  end

  describe "available_adjacent_locations/2" do
    test "provides up down left and right when all are available" do
      terrain = ~t/111
                   111
                   111/

      game = Game.new(terrain: terrain)

      assert Enum.sort([{0, 1}, {2, 1}, {1, 0}, {1, 2}]) ==
               Enum.sort(Game.available_adjacent_locations(game, {1, 1}))
    end

    test "doesn't provide spaces outside the map" do
      terrain = ~t/1/

      game = Game.new(terrain: terrain)
      assert [] == Game.available_adjacent_locations(game, {0, 0})
    end

    test "doesn't provide spaces that are inaccesible" do
      terrain = ~t/000
                   010
                   000/

      game = Game.new(terrain: terrain)
      assert [] == Game.available_adjacent_locations(game, {1, 1})
    end
  end
end
