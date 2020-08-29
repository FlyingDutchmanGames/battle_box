defmodule BattleBox.GameEngine.GameServerTest do
  alias BattleBox.{Game, GameEngine, GameEngine.GameServer, Games.RobotGame}
  alias BattleBox.Games.RobotGame.Settings.Terrain
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]
  use BattleBox.DataCase

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    {:ok, user} = create_user()
    {:ok, rg_arena} = robot_game_arena(%{user: user, arena_name: "test-rg-arena"})

    %{
      rg_init_opts: %{
        players: %{
          1 => named_proxy(:player_1),
          2 => named_proxy(:player_2)
        },
        game: %Game{
          id: Ecto.UUID.generate(),
          arena: rg_arena,
          arena_id: rg_arena.id,
          game_type: RobotGame,
          game_bots: [],
          robot_game: %RobotGame{}
        }
      },
      arena: rg_arena
    }
  end

  test "you can start the game server", context do
    {:ok, pid} = GameEngine.start_game(context.game_engine, context.rg_init_opts)
    assert Process.alive?(pid)
  end

  test "you can get the game from it", context do
    {:ok, pid} = GameEngine.start_game(context.game_engine, context.rg_init_opts)
    {:ok, game} = GameServer.get_game(pid)
    assert game == context.rg_init_opts.game
  end

  test "game servers emit a game start event", %{rg_init_opts: %{game: %{id: id}}} = context do
    :ok =
      GameEngine.subscribe_to_arena_events(context.game_engine, context.arena.id, [:game_start])

    {:ok, _pid} = GameEngine.start_game(context.game_engine, context.rg_init_opts)
    assert_receive {{:arena, _}, :game_start, ^id}
  end

  test "the game server registers in the registry", context do
    assert Registry.count(context.game_registry) == 0
    {:ok, pid} = GameEngine.start_game(context.game_engine, context.rg_init_opts)
    assert Registry.count(context.game_registry) == 1

    assert [{^pid, %{started_at: started_at, game: game}}] =
             Registry.lookup(context.game_registry, context.rg_init_opts.game.id)

    assert game == Game.metadata_only(context.rg_init_opts.game)
    assert DateTime.diff(DateTime.utc_now(), started_at) < 2
  end

  test "The game server sends out game update messages", context do
    game_id = context.rg_init_opts.game.id
    GameEngine.subscribe_to_game_events(context.game_engine, game_id, [:game_update])
    {:ok, _pid} = GameEngine.start_game(context.game_engine, context.rg_init_opts)
    assert_receive {{:game, ^game_id}, :game_update, ^game_id}
  end

  test "the starting of the game server will send init messages to p1 & p2", context do
    {:ok, pid} = GameEngine.start_game(context.game_engine, context.rg_init_opts)
    game = context.rg_init_opts.game

    expected = %{
      game_server: pid,
      game_id: game.id,
      accept_time: 2000,
      game_type: :robot_game,
      settings: %{
        spawn_every: game.robot_game.spawn_every,
        spawn_per_player: game.robot_game.spawn_per_player,
        robot_hp: game.robot_game.robot_hp,
        attack_damage_min: game.robot_game.attack_damage_min,
        attack_damage_max: game.robot_game.attack_damage_max,
        collision_damage_min: game.robot_game.collision_damage_min,
        collision_damage_max: game.robot_game.collision_damage_max,
        explode_damage_min: game.robot_game.explode_damage_min,
        explode_damage_max: game.robot_game.explode_damage_max,
        max_turns: game.robot_game.max_turns,
        terrain_base64: Base.encode64(Terrain.default())
      }
    }

    expected_p1 = {:player_1, {:game_request, Map.put(expected, :player, 1)}}
    expected_p2 = {:player_2, {:game_request, Map.put(expected, :player, 2)}}

    assert_receive ^expected_p1
    assert_receive ^expected_p2
  end

  describe "failure to accept game" do
    test "if a player rejects the game both get a cancelled message", context do
      {:ok, pid} = GameEngine.start_game(context.game_engine, context.rg_init_opts)

      ref = Process.monitor(pid)

      assert :ok = GameServer.accept_game(pid, 1)
      assert :ok = GameServer.reject_game(pid, 2)

      game_id = context.rg_init_opts.game.id

      assert_receive {:player_1, {:game_cancelled, ^game_id}}
      assert_receive {:player_2, {:game_cancelled, ^game_id}}
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end

    test "if a player dies during game acceptance, the game is cancelled", context do
      {:ok, pid} = GameEngine.start_game(context.game_engine, context.rg_init_opts)
      Process.flag(:trap_exit, true)

      game_ref = Process.monitor(pid)

      assert :ok = GameServer.accept_game(pid, 1)

      player_2_pid = context.rg_init_opts.players[2]

      Process.exit(player_2_pid, :kill)
      assert_receive {:EXIT, ^player_2_pid, :killed}

      game_id = context.rg_init_opts.game.id

      assert_receive {:player_1, {:game_cancelled, ^game_id}}
      assert_receive {:DOWN, ^game_ref, :process, ^pid, :normal}
    end
  end

  test "When you accept a game it asks you for moves", context do
    {:ok, pid} = GameEngine.start_game(context.game_engine, context.rg_init_opts)

    :ok = GameServer.accept_game(pid, 1)
    :ok = GameServer.accept_game(pid, 2)

    game_id = context.rg_init_opts.game.id

    assert_receive {:player_1,
                    {:commands_request,
                     %{
                       game_id: ^game_id,
                       maximum_time: 1000,
                       minimum_time: 20,
                       game_state: %{robots: [], turn: 0},
                       player: 1
                     }}}

    assert_receive {:player_2,
                    {:commands_request,
                     %{
                       game_id: ^game_id,
                       maximum_time: 1000,
                       minimum_time: 20,
                       game_state: %{robots: [], turn: 0},
                       player: 2
                     }}}
  end

  test "if you forefit, you get a game over message/ the other player wins", context do
    {:ok, pid} = GameEngine.start_game(context.game_engine, context.rg_init_opts)

    :ok = GameServer.accept_game(pid, 1)
    :ok = GameServer.accept_game(pid, 2)
    :ok = GameServer.forfeit_game(pid, 1)

    assert_receive {:player_1, {:game_over, %{}}}
    assert_receive {:player_2, {:game_over, %{}}}
  end

  test "if you die its the same as a forefit", context do
    Process.flag(:trap_exit, true)
    {:ok, pid} = GameEngine.start_game(context.game_engine, context.rg_init_opts)

    :ok = GameServer.accept_game(pid, 1)
    :ok = GameServer.accept_game(pid, 2)

    player_2_pid = context.rg_init_opts.players[2]

    Process.exit(player_2_pid, :kill)
    assert_receive {:EXIT, ^player_2_pid, :killed}

    assert_receive {:player_1, {:game_over, %{}}}
  end

  test "you can play a game! (and it persists it to the db when you're done)", context do
    game = %Game{
      id: Ecto.UUID.generate(),
      arena: context.arena,
      arena_id: context.arena.id,
      game_type: RobotGame,
      game_bots: [],
      robot_game: %RobotGame{max_turns: 10}
    }

    {:ok, pid} = GameEngine.start_game(context.game_engine, %{context.rg_init_opts | game: game})

    ref = Process.monitor(pid)

    assert_receive {:player_1, {:game_request, %{game_server: ^pid, player: 1, game_id: game_id}}}

    assert_receive {:player_2,
                    {:game_request, %{game_server: ^pid, player: 2, game_id: ^game_id}}}

    assert :ok = GameServer.accept_game(pid, 1)
    assert :ok = GameServer.accept_game(pid, 2)

    Enum.each(0..9, fn turn ->
      receive do
        {:player_1, {:commands_request, %{game_state: %{turn: ^turn}}}} ->
          GameServer.submit_commands(pid, 1, [])
      after
        100 -> raise "FAIL FOR TURN #{turn}"
      end

      receive do:
                ({:player_2, {:commands_request, %{game_state: %{turn: ^turn}}}} ->
                   GameServer.submit_commands(pid, 2, []))
    end)

    assert_receive {:player_1, {:game_over, %{game_id: ^game_id}}}
    assert_receive {:player_2, {:game_over, %{game_id: ^game_id}}}
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

    loaded_game = Repo.get(Game, game_id)
    refute is_nil(loaded_game)
  end
end
