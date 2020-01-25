defmodule BattleBox.Games.RobotGame.GameServerTest do
  alias BattleBox.Games.RobotGame.{Game, GameServer}
  use ExUnit.Case, async: true

  @player_1 Ecto.UUID.generate()
  @player_2 Ecto.UUID.generate()

  test "you can start the game server" do
    {:ok, pid} =
      GameServer.start_link(%{
        player_1: self(),
        player_2: self(),
        game: Game.new(player_1: @player_1, player_2: @player_2)
      })

    assert Process.alive?(pid)
  end

  test "the starting of the game server will send init messages to p1 & p2" do
    game = Game.new(player_1: @player_1, player_2: @player_2)

    {:ok, pid} =
      GameServer.start_link(%{
        player_1: self(),
        player_2: self(),
        game: game
      })

    expected = %{
      game_server: pid,
      player: nil,
      settings: %{
        spawn_every: game.spawn_every,
        spawn_per_player: game.spawn_per_player,
        robot_hp: game.robot_hp,
        attack_damage: game.attack_damage,
        collision_damage: game.collision_damage,
        terrain: game.terrain,
        game_acceptance_timeout_ms: game.game_acceptance_timeout_ms,
        move_timeout_ms: game.move_timeout_ms
      }
    }

    expected_p1 = {:game_request, %{expected | player: :player_1}}
    expected_p2 = {:game_request, %{expected | player: :player_2}}

    assert_receive ^expected_p1
    assert_receive ^expected_p2
  end

  # describe "failure to accept game" do
  #   test "if player 1 doesn't ack and player 2 does, then player 2 wins and the game server stops"
  #   test "if player 1 acks and player 2 doesn't, then player 1 wins and the game server stops"
  #   test "if neither player acks, the game is a push and an error is logged and the game server stops"
  # end
  #
  test "When you accept a game it asks you for moves" do
    game = Game.new(player_1: @player_1, player_2: @player_2)
    test_pid = self()

    helper_1 =
      spawn_link(fn ->
        receive do
          {:moves_request, %{}} -> send(test_pid, :success_1)
        end
      end)

    helper_2 =
      spawn_link(fn ->
        receive do
          {:moves_request, %{}} -> send(test_pid, :success_2)
        end
      end)

    {:ok, pid} =
      GameServer.start_link(%{
        player_1: helper_1,
        player_2: helper_2,
        game: game
      })

    :ok = GameServer.accept_game(pid, :player_1)
    :ok = GameServer.accept_game(pid, :player_2)
    assert_receive :success_1
    assert_receive :success_2
  end

  test "you can play a game!" do
    game = Game.new(player_1: @player_1, player_2: @player_2)

    {:ok, pid} =
      GameServer.start_link(%{
        player_1: self(),
        player_2: self(),
        game: game
      })

    assert_receive {:game_request, %{game_server: ^pid, player: :player_1}}
    assert_receive {:game_request, %{game_server: ^pid, player: :player_2}}

    assert :ok = GameServer.accept_game(pid, :player_1)
    assert :ok = GameServer.accept_game(pid, :player_2)
  end
end
