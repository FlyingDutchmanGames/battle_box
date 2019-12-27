defmodule BattleBox.Games.RobotGame.GameTest do
  use BattleBox.DataCase
  alias BattleBox.Games.RobotGame.{Game, Robot}
  import BattleBox.Games.RobotGame.Terrain.Helpers
  import BattleBox.Games.RobotGameTest.Helpers

  @player_1 Ecto.UUID.generate()
  @player_2 Ecto.UUID.generate()

  describe "new/1" do
    test "you can override any top level key" do
      assert %{turn: 42} = Game.new(turn: 42)
      assert %{suicide_damage: 15, robot_hp: 42} = Game.new(suicide_damage: 15, robot_hp: 42)
    end
  end

  describe "persistance" do
    test "You can persist a game" do
      game = Game.new(player_1: @player_1, player_2: @player_2)
      assert {:ok, _} = Game.persist(game)
    end

    test "trying to get a game that doesnt exist yields nil" do
      assert nil == Game.get_by_id(Ecto.UUID.generate())
    end

    test "you can get a game you persisted (and it will include turns)" do
      game = Game.new(player_1: @player_1, player_2: @player_2)
      assert {:ok, game} = Game.persist(game)
      expected = %{id: game.id, turns: []}
      assert expected == Game.get_by_id(game.id) |> Map.take([:id, :turns])
    end

    test "you can persist a game twice" do
      game = Game.new(player_1: @player_1, player_2: @player_2)
      assert {:ok, persisted_game} = Game.persist(game)
      persisted_game = Repo.preload(persisted_game, :turns)
      assert {:ok, _} = Game.persist(persisted_game)
    end

    test "when you persist a game it flushes the turns unpersisted events to disk" do
      game = Game.new(player_1: @player_1, player_2: @player_2)

      game =
        Game.apply_event(game, %{
          cause: :spawn,
          effects: [{:create_robot, :player_1, uuid(), {0, 0}, %{}}]
        })

      {:ok, game} = Game.persist(game)

      reloaded_game = Game.get_by_id(game.id)
      assert normalize_turns(game.turns) == normalize_turns(reloaded_game.turns)
      assert game.robots == reloaded_game.robots
      assert game.unpersisted_events == []
    end

    test "you can persist a new turn to a game that already has a turn" do
      game = Game.new(player_1: @player_1, player_2: @player_2)

      game =
        Game.apply_event(game, %{
          cause: :spawn,
          effects: [{:create_robot, :player_1, uuid(), {0, 0}, %{}}]
        })

      {:ok, game} = Game.persist(game)

      game = Game.complete_turn(game)

      game =
        Game.apply_event(game, %{
          cause: :spawn,
          effects: [{:create_robot, :player_1, uuid(), {1, 1}, %{}}]
        })

      {:ok, game} = Game.persist(game)
      reloaded_game = Game.get_by_id(game.id)
      assert normalize_turns(game.turns) == normalize_turns(reloaded_game.turns)
      assert game.robots == reloaded_game.robots
      assert game.unpersisted_events == []
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
      robot_spawns = ~g/1/

      game =
        Game.new()
        |> Game.apply_events(robot_spawns)

      assert 1 == Game.score(game, :player_1)
      assert 0 == Game.score(game, :player_2)
    end
  end

  describe "get_robot_at_location/2" do
    test "it gives nil if there isn't a robot at that location" do
      assert nil == Game.get_robot_at_location(Game.new(), {0, 0})
    end

    test "it can give back a robot if there is one at a location" do
      robot_spawns = ~g/1/
      robot = %{player_id: :player_1, id: 1, location: {0, 0}, hp: 50}

      assert Robot.new(robot) ==
               Game.apply_events(Game.new(), robot_spawns)
               |> Game.get_robot_at_location({0, 0})
    end
  end

  describe "apply_events" do
    test "applying an event appends the turn to the log item" do
      game = Game.new(turn: 42)
      game = Game.apply_event(game, %{move: :test, effects: []})
      assert [%{turn: 42} | _] = game.unpersisted_events
    end

    test "you can create a guard move" do
      robot_spawns = ~g/1/
      game = Game.new() |> Game.apply_events(robot_spawns)
      game = Game.apply_event(game, %{move: %{type: :guard}, effects: [{:guard, 1}]})
      assert [%{effects: [guard: 1], move: %{type: :guard}} | _] = game.unpersisted_events
    end
  end

  describe "apply_events (:create_robot)" do
    test "you can create a robot" do
      game = Game.new()
      id = uuid()
      effect = {:create_robot, :player_1, id, {42, 42}, %{}}
      game = Game.apply_event(game, %{move: :test, effects: [effect]})

      assert [%{id: ^id, player_id: :player_1, location: {42, 42}, hp: 50}] = game.robots
    end

    test "you can create a robot with special characteristics" do
      id = uuid()
      game = Game.new()
      effect = {:create_robot, :player_1, id, {42, 42}, %{hp: 42}}
      game = Game.apply_event(game, %{move: :test, effects: [effect]})
      assert [%{id: ^id, player_id: :player_1, location: {42, 42}, hp: 42}] = game.robots
    end
  end

  describe "apply_event :move" do
    test "you can move a robot" do
      robot_spawns = ~g/1/
      game = Game.new() |> Game.apply_events(robot_spawns)
      game = Game.apply_effect(game, {:move, 1, {0, 1}})
      [%{location: {0, 1}, id: 1}] = Game.robots(game)
    end

    test "trying to move a non existant robot is a no-op" do
    end
  end

  # describe "apply_event :damage"
  describe "apply_event :remove_robot" do
    test "you can remove a robot" do
      game = Game.new()
      robot_spawns = ~g/1/
      game = Game.apply_events(game, robot_spawns)
      assert 1 == game |> Game.robots() |> length
      game = Game.apply_effect(game, {:remove_robot, 1})
      assert 0 == game |> Game.robots() |> length
    end

    test "trying to remove a robot that doesn't exist doesn't raise an error" do
      game = Game.new()
      assert 0 == game |> Game.robots() |> length
      game = Game.apply_effect(game, {:remove_robot, "DOESN'T EXIST"})
      assert 0 == game |> Game.robots() |> length
    end
  end

  # describe "move_robot/3" do
  #   test "trying to move a robot that doesn't exist is a noop" do
  #     game = Game.new()
  #     assert ^game = Game.move_robot(game, "DOES_NOT_EXIST", {42, 42})
  #   end

  #   test "you can move a robot" do
  #     assert [%{location: {42, 42}}] =
  #              Game.new()
  #              |> Game.add_robot(%{player_id: :player_1, id: "TEST", location: {0, 0}})
  #              |> Game.move_robot("TEST", {42, 42})
  #              |> Game.robots()
  #   end
  # end

  describe "get_robot/2" do
    test "you can get a robot by id" do
      robot_spawns = ~g/1/
      robot = %{player_id: :player_1, location: {0, 0}, id: 1, hp: 50}

      game = Game.apply_events(Game.new(), robot_spawns)
      assert Robot.new(robot) == Game.get_robot(game, 1)
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

  defp normalize_turns(turns) do
    Enum.map(turns, fn turn ->
      %{turn | __meta__: nil, events: Enum.map(turn.events, &Map.delete(&1, :__meta__))}
    end)
  end

  defp uuid(), do: Ecto.UUID.generate()
end
