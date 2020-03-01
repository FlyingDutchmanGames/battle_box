defmodule BattleBox.GameEngine.GameServerTest do
  alias BattleBox.{Game, GameEngine, GameEngine.GameServer, Games.RobotGame}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]
  use BattleBox.DataCase

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    %{
      init_opts: %{
        players: %{
          "player_1" => named_proxy(:player_1),
          "player_2" => named_proxy(:player_2)
        },
        game: Game.new(robot_game: RobotGame.new())
      }
    }
  end

  test "you can start the game server", context do
    {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)

    assert Process.alive?(pid)
  end

  test "the game server registers in the registry", context do
    assert Registry.count(context.game_registry) == 0
    {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)
    assert Registry.count(context.game_registry) == 1

    assert [{^pid, %{started_at: started_at, game: game}}] =
             Registry.lookup(context.game_registry, context.init_opts.game.id)

    assert game == context.init_opts.game
    assert DateTime.diff(DateTime.utc_now(), started_at) < 2
  end

  test "The game server sends out game update messages", context do
    game_id = context.init_opts.game.id
    GameEngine.subscribe(context.game_engine, "game:#{game_id}")
    {:ok, _pid} = GameEngine.start_game(context.game_engine, context.init_opts)
    assert_receive {:game_update, ^game_id}
  end

  test "the starting of the game server will send init messages to p1 & p2", context do
    {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)
    game = context.init_opts.game

    expected = %{
      game_server: pid,
      game_id: game.id,
      settings: %{
        spawn_every: game.robot_game.settings.spawn_every,
        spawn_per_player: game.robot_game.settings.spawn_per_player,
        robot_hp: game.robot_game.settings.robot_hp,
        attack_damage: game.robot_game.settings.attack_damage,
        collision_damage: game.robot_game.settings.collision_damage,
        max_turns: game.robot_game.settings.max_turns
      }
    }

    expected_p1 = {:player_1, {:game_request, Map.put(expected, :player, "player_1")}}
    expected_p2 = {:player_2, {:game_request, Map.put(expected, :player, "player_2")}}

    assert_receive ^expected_p1
    assert_receive ^expected_p2
  end

  describe "failure to accept game" do
    test "if a player rejects the game both get a cancelled message", context do
      {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)

      ref = Process.monitor(pid)

      assert :ok = GameServer.accept_game(pid, "player_1")
      assert :ok = GameServer.reject_game(pid, "player_2")

      game_id = context.init_opts.game.id

      assert_receive {:player_1, {:game_cancelled, ^game_id}}
      assert_receive {:player_2, {:game_cancelled, ^game_id}}
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end

    test "if a player dies during game acceptance, the game is cancelled", context do
      {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)
      Process.flag(:trap_exit, true)

      game_ref = Process.monitor(pid)

      assert :ok = GameServer.accept_game(pid, "player_1")

      player_2_pid = context.init_opts.players["player_2"]

      Process.exit(player_2_pid, :kill)
      assert_receive {:EXIT, ^player_2_pid, :killed}

      game_id = context.init_opts.game.id

      assert_receive {:player_1, {:game_cancelled, ^game_id}}
      assert_receive {:DOWN, ^game_ref, :process, ^pid, :normal}
    end
  end

  test "When you accept a game it asks you for moves", context do
    {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)

    :ok = GameServer.accept_game(pid, "player_1")
    :ok = GameServer.accept_game(pid, "player_2")

    game_id = context.init_opts.game.id

    assert_receive {:player_1,
                    {:moves_request,
                     %{game_id: ^game_id, game_state: %{robots: [], turn: 0}, player: "player_1"}}}

    assert_receive {:player_2,
                    {:moves_request,
                     %{game_id: ^game_id, game_state: %{robots: [], turn: 0}, player: "player_2"}}}
  end

  test "if you forefit, you get a game over message/ the other player wins", context do
    {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)

    :ok = GameServer.accept_game(pid, "player_1")
    :ok = GameServer.accept_game(pid, "player_2")
    :ok = GameServer.forfeit_game(pid, "player_1")

    assert_receive {:player_1, {:game_over, %{winner: "player_2"}}}
    assert_receive {:player_2, {:game_over, %{winner: "player_2"}}}
  end

  test "if you die its the same as a forefit", context do
    Process.flag(:trap_exit, true)
    {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)

    :ok = GameServer.accept_game(pid, "player_1")
    :ok = GameServer.accept_game(pid, "player_2")

    player_2_pid = context.init_opts.players["player_2"]

    Process.exit(player_2_pid, :kill)
    assert_receive {:EXIT, ^player_2_pid, :killed}

    assert_receive {:player_1, {:game_over, %{winner: "player_1"}}}
  end

  test "you can play a game! (and it persists it to the db when you're done)", context do
    game = Game.new(robot_game: RobotGame.new(settings: %{max_turns: 10}))

    {:ok, pid} = GameEngine.start_game(context.game_engine, %{context.init_opts | game: game})

    ref = Process.monitor(pid)

    assert_receive {:player_1,
                    {:game_request, %{game_server: ^pid, player: "player_1", game_id: game_id}}}

    assert_receive {:player_2,
                    {:game_request, %{game_server: ^pid, player: "player_2", game_id: ^game_id}}}

    assert :ok = GameServer.accept_game(pid, "player_1")
    assert :ok = GameServer.accept_game(pid, "player_2")

    Enum.each(0..9, fn turn ->
      receive do
        {:player_1, {:moves_request, %{game_state: %{turn: ^turn}}}} ->
          GameServer.submit_moves(pid, "player_1", [])
      after
        100 -> raise "FAIL"
      end

      receive do:
                ({:player_2, {:moves_request, %{game_state: %{turn: ^turn}}}} ->
                   GameServer.submit_moves(pid, "player_2", []))
    end)

    assert_receive {:player_1, {:game_over, %{game_id: ^game_id}}}
    assert_receive {:player_2, {:game_over, %{game_id: ^game_id}}}
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

    loaded_game = Game.get_by_id(game_id)
    refute is_nil(loaded_game)
  end
end
