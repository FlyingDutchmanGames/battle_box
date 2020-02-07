defmodule BattleBox.GameServer.GameServerTest do
  alias BattleBox.{GameEngine, GameServer}
  alias BattleBox.Games.RobotGame.Game
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]
  use BattleBox.DataCase

  @player_1 Ecto.UUID.generate()
  @player_2 Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    %{
      player_1_pid: named_proxy(:player_1),
      player_2_pid: named_proxy(:player_2),
      game: Game.new(player_1: @player_1, player_2: @player_2)
    }
  end

  test "you can start the game server", context do
    {:ok, pid} =
      GameEngine.start_game(context.game_engine, %{
        player_1: context.player_1_pid,
        player_2: context.player_2_pid,
        game: context.game
      })

    assert Process.alive?(pid)
  end

  test "the starting of the game server will send init messages to p1 & p2", context do
    {:ok, pid} =
      GameEngine.start_game(context.game_engine, %{
        player_1: context.player_1_pid,
        player_2: context.player_2_pid,
        game: context.game
      })

    expected = %{
      game_server: pid,
      game_id: context.game.id,
      settings: %{
        spawn_every: context.game.spawn_every,
        spawn_per_player: context.game.spawn_per_player,
        robot_hp: context.game.robot_hp,
        attack_damage: context.game.attack_damage,
        collision_damage: context.game.collision_damage,
        terrain: context.game.terrain,
        game_acceptance_timeout_ms: context.game.game_acceptance_timeout_ms,
        move_timeout_ms: context.game.move_timeout_ms
      }
    }

    expected_p1 = {:player_1, {:game_request, Map.put(expected, :player, :player_1)}}
    expected_p2 = {:player_2, {:game_request, Map.put(expected, :player, :player_2)}}

    assert_receive ^expected_p1
    assert_receive ^expected_p2
  end

  describe "failure to accept game" do
    test "if a player rejects the game both get a cancelled message", context do
      {:ok, pid} =
        GameEngine.start_game(context.game_engine, %{
          player_1: context.player_1_pid,
          player_2: context.player_2_pid,
          game: context.game
        })

      ref = Process.monitor(pid)

      assert :ok = GameServer.accept_game(pid, :player_1)
      assert :ok = GameServer.reject_game(pid, :player_2)

      game_id = context.game.id

      assert_receive {:player_1, {:game_cancelled, ^game_id}}
      assert_receive {:player_2, {:game_cancelled, ^game_id}}
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end
  end

  test "When you accept a game it asks you for moves", context do
    {:ok, pid} =
      GameEngine.start_game(context.game_engine, %{
        player_1: context.player_1_pid,
        player_2: context.player_2_pid,
        game: context.game
      })

    :ok = GameServer.accept_game(pid, :player_1)
    :ok = GameServer.accept_game(pid, :player_2)

    game_id = context.game.id

    assert_receive {:player_1,
                    {:moves_request,
                     %{game_id: ^game_id, turn: 0, game_state: %{robots: []}, player: :player_1}}}

    assert_receive {:player_2,
                    {:moves_request,
                     %{game_id: ^game_id, turn: 0, game_state: %{robots: []}, player: :player_2}}}
  end

  test "if you forefit, you get a game over message and the other player is set as the winner",
       context do
    {:ok, pid} =
      GameEngine.start_game(context.game_engine, %{
        player_1: context.player_1_pid,
        player_2: context.player_2_pid,
        game: context.game
      })

    :ok = GameServer.accept_game(pid, :player_1)
    :ok = GameServer.accept_game(pid, :player_2)
    :ok = GameServer.forfeit_game(pid, :player_1)

    assert_receive {:player_1, {:game_over, %{game: %{winner: @player_2}}}}
    assert_receive {:player_2, {:game_over, %{game: %{winner: @player_2}}}}
  end

  test "you can play a game! (and it persists it to the db when you're done)", context do
    game = Game.new(player_1: @player_1, player_2: @player_2, max_turns: 10)

    {:ok, pid} =
      GameEngine.start_game(context.game_engine, %{
        player_1: context.player_1_pid,
        player_2: context.player_2_pid,
        game: game
      })

    ref = Process.monitor(pid)

    assert_receive {:player_1, {:game_request, %{game_server: ^pid, player: :player_1}}}
    assert_receive {:player_2, {:game_request, %{game_server: ^pid, player: :player_2}}}

    assert :ok = GameServer.accept_game(pid, :player_1)
    assert :ok = GameServer.accept_game(pid, :player_2)

    Enum.each(0..9, fn turn ->
      receive do:
                ({:player_1, {:moves_request, %{turn: ^turn}}} ->
                   GameServer.submit_moves(pid, :player_1, turn, []))

      receive do:
                ({:player_2, {:moves_request, %{turn: ^turn}}} ->
                   GameServer.submit_moves(pid, :player_2, turn, []))
    end)

    assert_receive {:player_1, {:game_over, %{game: game}}}
    assert_receive {:player_2, {:game_over, %{game: ^game}}}
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

    loaded_game = Game.get_by_id(game.id)
    assert Enum.map(loaded_game.events, & &1.effects) == Enum.map(game.events, & &1.effects)
  end
end
