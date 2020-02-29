defmodule BattleBox.Games.RobotGame.GameTest do
  use BattleBox.DataCase
  alias BattleBox.Games.RobotGame
  import BattleBox.Games.RobotGame.Settings.Terrain.Helpers
  import BattleBox.Games.RobotGameTest.Helpers

  @game_id Ecto.UUID.generate()
  @bot_id Ecto.UUID.generate()

  describe "new/1" do
    test "you can override any top level key" do
      assert %{turn: 42} = RobotGame.new(turn: 42)

      assert %{settings: %{suicide_damage: 15, robot_hp: 42}} =
               RobotGame.new(settings: %{suicide_damage: 15, robot_hp: 42})
    end

    test "it will auto generate an id if one isn't provided" do
      assert <<_::288>> = RobotGame.new().id
    end

    test "it will not override a passed id" do
      assert RobotGame.new(id: @game_id).id == @game_id
    end
  end

  describe "complete turn" do
    test "you can complete the turn on a new game" do
      game = RobotGame.new()
      assert game.turn == 0
      game = RobotGame.complete_turn(game)
      assert game.turn == 1
    end

    test "you can complete a turn on an existing game" do
      game = RobotGame.new(turn: 10)
      assert game.turn == 10
      game = RobotGame.complete_turn(game)
      assert game.turn == 11
    end
  end

  describe "validate_moves" do
    test "it will remove moves that are duplicates for a robot" do
      robot_spawns = ~g/1/

      game =
        RobotGame.new()
        |> RobotGame.put_events(robot_spawns)

      assert [
               %{"type" => "move", "robot_id" => 1, "target" => [1, 0]}
             ] ==
               RobotGame.validate_moves(
                 game,
                 [
                   %{"type" => "move", "robot_id" => 1, "target" => [1, 0]},
                   %{"type" => "move", "robot_id" => 1, "target" => [0, 1]}
                 ],
                 "player_1"
               )
    end

    test "it will remove moves that are not for the player" do
      robot_spawns = ~g/1/

      game =
        RobotGame.new()
        |> RobotGame.put_events(robot_spawns)

      assert [] ==
               RobotGame.validate_moves(
                 game,
                 [%{"type" => "move", "robot_id" => 1, "target" => [1, 0]}],
                 "player_2"
               )
    end
  end

  describe "over?" do
    test "the game is over if there is a winner" do
      game = RobotGame.new(winner: uuid())
      assert RobotGame.over?(game)
    end

    test "is over if the game turn is equal to max turn" do
      game = RobotGame.new(turn: 10, settings: %{max_turns: 10})
      assert RobotGame.over?(game)
    end

    test "is over if the game turn is more than the max turn" do
      game = RobotGame.new(turn: 11, settings: %{max_turns: 10})
      assert RobotGame.over?(game)
    end

    test "is not over if the game turn is less than the max turn" do
      game = RobotGame.new(turn: 9, settings: %{max_turns: 10})
      refute RobotGame.over?(game)
    end
  end

  describe "persistance" do
    test "You can persist a game" do
      game = RobotGame.new()
      assert {:ok, _} = RobotGame.persist(game)
    end

    test "persisting will persist the battle box game, and puts scores on the players" do
      # TODO:// This feels like it doesn't belong here with this many imports
      alias BattleBox.{Game, GameBot, Repo}

      bbg =
        Game.new(
          game_bots: [
            GameBot.new(player: "player_1", bot_id: @bot_id)
          ]
        )

      {:ok, game} =
        RobotGame.new(game: bbg)
        |> RobotGame.put_event(%{
          cause: "spawn",
          effects: [["create_robot", "player_1", uuid(), 50, [1, 1]]]
        })
        |> RobotGame.persist()

      game = RobotGame.get_by_id(game.id)

      [bot] = Repo.preload(game, game: [:game_bots]).game.game_bots

      assert bot.score == 1
    end

    test "trying to get a game that doesnt exist yields nil" do
      assert nil == RobotGame.get_by_id(Ecto.UUID.generate())
    end

    test "trying to perist a game that has persistent?: false is a noop" do
      game = RobotGame.new(settings: %{persistent?: false})
      assert {:ok, game} = RobotGame.persist(game)
      refute is_nil(game.id)
      assert nil == RobotGame.get_by_id(game.id)
    end

    test "you can persist a game twice" do
      game = RobotGame.new()
      assert {:ok, game} = RobotGame.persist(game)
      assert {:ok, _} = RobotGame.persist(game)
    end

    test "you can persist changes multiple time" do
      game = RobotGame.new(settings: %{terrain: %{}})
      assert {:ok, game} = RobotGame.persist(game)
      game = RobotGame.complete_turn(game)
      {:ok, game} = RobotGame.persist(game)
      assert 1 == RobotGame.get_by_id(game.id).turn
    end

    test "when you persist a game it flushes the unpersisted events to disk" do
      game = RobotGame.new()

      game =
        RobotGame.put_event(game, %{
          cause: "spawn",
          effects: [["create_robot", "player_1", uuid(), 50, [0, 0]]]
        })

      {:ok, game} = RobotGame.persist(game)

      reloaded_game = RobotGame.get_by_id(game.id)
      assert normalize_events(game.events) == normalize_events(reloaded_game.events)
      assert RobotGame.robots(game) == RobotGame.robots(reloaded_game)
    end

    test "you can persist a new turn to a game that already has a turn" do
      game = RobotGame.new()

      game =
        RobotGame.put_event(game, %{
          cause: "spawn",
          effects: [["create_robot", "player_1", uuid(), 50, [0, 0]]]
        })

      {:ok, game} = RobotGame.persist(game)

      game = RobotGame.complete_turn(game)

      game =
        RobotGame.put_event(game, %{
          cause: "spawn",
          effects: [["create_robot", "player_1", uuid(), 50, [1, 1]]]
        })

      {:ok, game} = RobotGame.persist(game)
      reloaded_game = RobotGame.get_by_id(game.id)

      assert RobotGame.robots(game) == RobotGame.robots(reloaded_game)
      assert normalize_events(game.events) == normalize_events(reloaded_game.events)
    end
  end

  describe "spawning_round?/1" do
    test "it knows if its a spawning round based on the turn and spawn_every param" do
      should_spawn = [
        # Spawn when the turn is a multiple of the 'spawn_every' setting
        %{turn: 10, settings: %{spawn_every: 1}},
        %{turn: 10, settings: %{spawn_every: 2}},
        %{turn: 10, settings: %{spawn_every: 5}},
        %{turn: 10, settings: %{spawn_every: 10}},
        %{turn: 20, settings: %{spawn_every: 10}},
        # Always spawn on the first (0th) turn
        %{turn: 0, settings: %{spawn_every: 1}},
        %{turn: 0, settings: %{spawn_every: 2}},
        %{turn: 0, settings: %{spawn_every: 12_323_123_123}}
      ]

      Enum.each(should_spawn, fn setup ->
        game = RobotGame.new(setup)
        assert RobotGame.spawning_round?(game)
      end)

      should_not_spawn = [
        %{turn: 10, settings: %{spawn_every: 3}},
        %{turn: 10, settings: %{spawn_every: 14}},
        %{turn: 10, settings: %{spawn_every: 20}}
      ]

      Enum.each(should_not_spawn, fn setup ->
        game = RobotGame.new(setup)
        refute RobotGame.spawning_round?(game)
      end)
    end

    test "spawn_enabled: false is never a spawning round" do
      refute RobotGame.spawning_round?(
               RobotGame.new(settings: %{spawn_enabled: false, spawn_every: 10, turn: 10})
             )
    end
  end

  describe "score" do
    test "A player with robots is the the number of robots, a player with no robots is 0" do
      robot_spawns = ~g/1/

      game =
        RobotGame.new()
        |> RobotGame.put_events(robot_spawns)

      assert %{"player_1" => 1, "player_2" => 0} == RobotGame.score(game)
    end
  end

  describe "get_robot_at_location/2" do
    test "it gives nil if there isn't a robot at that location" do
      assert nil == RobotGame.get_robot_at_location(RobotGame.new(), {0, 0})
    end

    test "it can give back a robot if there is one at a location" do
      robot_spawns = ~g/1/
      robot = %{player_id: "player_1", id: 1, location: [0, 0], hp: 50}

      assert robot ==
               RobotGame.put_events(RobotGame.new(), robot_spawns)
               |> RobotGame.get_robot_at_location([0, 0])
    end
  end

  describe "put_events" do
    test "applying an event appends the turn to the log item" do
      game = RobotGame.new(turn: 42)
      game = RobotGame.put_event(game, %{move: :test, effects: []})
      assert [%{turn: 42} | _] = game.events
    end

    test "you can create a guard move" do
      robot_spawns = ~g/1/
      game = RobotGame.new() |> RobotGame.put_events(robot_spawns)
      game = RobotGame.put_event(game, %{move: %{type: :guard}, effects: [{:guard, 1}]})
      assert [%{effects: [guard: 1], move: %{type: :guard}} | _] = game.events
    end
  end

  describe "put_events (create_robot)" do
    test "you can create a robot" do
      game = RobotGame.new()
      id = uuid()
      effect = ["create_robot", "player_1", id, 42, [42, 42]]
      game = RobotGame.put_event(game, %{move: :test, effects: [effect]})

      assert [%{id: ^id, player_id: "player_1", location: [42, 42], hp: 42}] =
               RobotGame.robots(game)
    end
  end

  describe "put_event :move" do
    test "you can move a robot" do
      robot_spawns = ~g/1/
      game = RobotGame.new() |> RobotGame.put_events(robot_spawns)
      robots = RobotGame.robots(game)
      robots = RobotGame.apply_effect_to_robots(robots, ["move", 1, [0, 1]])
      assert [%{location: [0, 1], id: 1}] = robots
    end
  end

  describe "put_event :damage" do
    test "you can damage a robot" do
      robot_spawns = ~g/1/
      game = RobotGame.new() |> RobotGame.put_events(robot_spawns)
      robots = RobotGame.robots(game)
      robots = RobotGame.apply_effect_to_robots(robots, ["damage", 1, 10])
      assert [%{hp: 40, id: 1}] = robots
    end
  end

  describe "put_event :remove_robot" do
    test "you can remove a robot" do
      game = RobotGame.new()
      robot_spawns = ~g/1/
      game = RobotGame.put_events(game, robot_spawns)
      robots = RobotGame.robots(game)

      assert 1 == length(robots)
      robots = RobotGame.apply_effect_to_robots(robots, ["remove_robot", 1])
      assert 0 == length(robots)
    end

    test "trying to remove a robot that doesn't exist doesn't raise an error" do
      robots = []
      robots = RobotGame.apply_effect_to_robots(robots, ["remove_robot", "DOESN'T EXIST"])
      assert robots == []
    end
  end

  describe "get_robot/2" do
    test "you can get a robot by id" do
      robot_spawns = ~g/1/
      robot = %{player_id: "player_1", location: [0, 0], id: 1, hp: 50}

      game = RobotGame.put_events(RobotGame.new(), robot_spawns)
      assert robot == RobotGame.get_robot(game, 1)
    end

    test "trying to get a robot by id that doesn't exist gives `nil`" do
      assert nil == RobotGame.get_robot(RobotGame.new(), "DOES_NOT_EXIST")
    end
  end

  describe "attack_damage" do
    test "you can get an attack damage" do
      game = RobotGame.new()
      damage = RobotGame.attack_damage(game)

      assert damage >= game.settings.attack_damage.min &&
               damage <= game.settings.attack_damage.max
    end

    test "guarded attack damage is 50% of regular damage rounding down to the integer" do
      game = RobotGame.new(settings: %{attack_damage: 100})
      assert 50 == RobotGame.guarded_attack_damage(game)

      game = RobotGame.new(settings: %{attack_damage: 99})
      assert 49 == RobotGame.guarded_attack_damage(game)
    end

    test "it works if the the min and max attack are the same" do
      game = RobotGame.new(settings: %{attack_damage: %{min: 50, max: 50}})
      assert 50 == RobotGame.attack_damage(game)
    end
  end

  describe "suicide_damage" do
    test "it gets the value set in settings" do
      assert 42 = RobotGame.suicide_damage(RobotGame.new(settings: %{suicide_damage: 42}))
    end

    test "guarded suicide damage is 50% of regular damage rounding down to the integer" do
      game = RobotGame.new(settings: %{suicide_damage: 10})
      assert 5 == RobotGame.guarded_suicide_damage(game)

      game = RobotGame.new(settings: %{suicide_damage: 9})
      assert 4 == RobotGame.guarded_suicide_damage(game)
    end
  end

  describe "adjacent_locations/1" do
    test "it provides the adjacent locations" do
      assert [[1, 0], [-1, 0], [0, 1], [0, -1]] = RobotGame.adjacent_locations([0, 0])
    end
  end

  describe "available_adjacent_locations/2" do
    test "provides up down left and right when all are available" do
      terrain = ~t/111
      111
      111/

      game = RobotGame.new(settings: %{terrain: terrain})

      assert Enum.sort([[0, 1], [2, 1], [1, 0], [1, 2]]) ==
               Enum.sort(RobotGame.available_adjacent_locations(game, [1, 1]))
    end

    test "doesn't provide spaces outside the map" do
      terrain = ~t/1/

      game = RobotGame.new(settings: %{terrain: terrain})
      assert [] == RobotGame.available_adjacent_locations(game, [0, 0])
    end

    test "doesn't provide spaces that are inaccesible" do
      terrain = ~t/000
      010
      000/

      game = RobotGame.new(settings: %{terrain: terrain})
      assert [] == RobotGame.available_adjacent_locations(game, [1, 1])
    end
  end

  describe "disqualify/3" do
    test "disqualifying a game for a player sets the other player as the winner" do
      game = RobotGame.new()

      assert game.winner == nil
      assert RobotGame.disqualify(game, "player_1").winner == "player_2"
      assert RobotGame.disqualify(game, "player_2").winner == "player_1"
    end
  end

  describe "calculate_winner/1" do
    test "calculate winner when its not at max turns yet doesn't set the winner" do
      robot_spawns = ~g/1/

      game =
        RobotGame.new()
        |> RobotGame.put_events(robot_spawns)

      refute RobotGame.over?(game)
      assert RobotGame.calculate_winner(game).winner == nil
    end

    test "will set the winner if the game is over to the player with the most robots" do
      robot_spawns = ~g/121/

      game =
        RobotGame.new(settings: %{max_turns: 0})
        |> RobotGame.put_events(robot_spawns)

      assert RobotGame.over?(game)
      assert RobotGame.calculate_winner(game).winner == "player_1"
    end

    test "will be nil if its a tie" do
      robot_spawns = ~g/1212/

      game =
        RobotGame.new(settings: %{max_turns: 0})
        |> RobotGame.put_events(robot_spawns)

      assert RobotGame.over?(game)
      assert RobotGame.calculate_winner(game).winner == nil
    end
  end

  defp normalize_events(events) do
    Enum.map(events, &Map.drop(&1, [:__meta__, :__struct__]))
  end

  defp uuid(), do: Ecto.UUID.generate()
end
