defmodule BattleBox.Games.RobotGame.DamageIntegrationTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.{Game, Game.Logic}
  import BattleBox.Games.RobotGame.Game.Terrain.Helpers
  import BattleBox.Games.RobotGameTest.Helpers

  @terrain ~t/1 1
              1 1/

  setup do
    %{
      game:
        Game.new(
          terrain: @terrain,
          spawn_enabled: false,
          attack_damage: 1,
          robot_hp: 50,
          suicide_damage: 5
        )
    }
  end

  test "If a robot goes to 0 health it disappears" do
    robot_spawns = ~g/1 2/
    game = Game.new(terrain: @terrain, spawn_enabled: false, attack_damage: 50, robot_hp: 50)
    inital_game = Game.put_events(game, robot_spawns)
    player_2_moves = [%{"type" => "attack", "target" => [0, 0], "robot_id" => 2}]
    after_turn = Logic.calculate_turn(inital_game, %{player_1: [], player_2: player_2_moves})

    assert nil == Game.get_robot(after_turn, 1)
  end

  test "If you attack a square a robot is in it takes damage", %{game: game} do
    robot_spawns = ~g/1 2/

    player_1_moves = [
      %{"type" => "noop", "robot_id" => 1}
    ]

    player_2_moves = [
      %{"type" => "attack", "target" => [0, 0], "robot_id" => 2}
    ]

    inital_game = Game.put_events(game, robot_spawns)

    after_turn =
      Logic.calculate_turn(inital_game, %{player_1: player_1_moves, player_2: player_2_moves})

    assert %{
             location: [0, 0],
             hp: 49
           } = Game.get_robot(after_turn, 1)
  end

  test "If you attack a robot that moves out of a square it takes not damage", %{game: game} do
    robot_spawns = ~g/1 2/

    player_1_moves = [
      %{"type" => "move", "target" => [1, 0], "robot_id" => 1}
    ]

    player_2_moves = [
      %{"type" => "attack", "target" => [0, 0], "robot_id" => 2}
    ]

    inital_game = Game.put_events(game, robot_spawns)

    after_turn =
      Logic.calculate_turn(inital_game, %{
        player_1: player_1_moves,
        player_2: player_2_moves
      })

    assert %{
             location: [1, 0],
             hp: 50
           } = Game.get_robot(after_turn, 1)
  end

  test "If you move into a square being attacked you take damage", %{game: game} do
    robot_spawns = ~g/1 0
                      0 2/

    player_1_moves = [
      %{"type" => "attack", "target" => [1, 0], "robot_id" => 1}
    ]

    player_2_moves = [
      %{"type" => "move", "target" => [1, 0], "robot_id" => 2}
    ]

    inital_game = Game.put_events(game, robot_spawns)

    after_turn =
      Logic.calculate_turn(inital_game, %{player_1: player_1_moves, player_2: player_2_moves})

    assert %{
             location: [1, 0],
             hp: 49
           } = Game.get_robot(after_turn, 2)
  end

  test "A robot can suffer multiple attacks", %{game: game} do
    robot_spawns = ~g/1 2
                      4 0/

    player_2_moves = [
      %{"type" => "attack", "target" => [0, 0], "robot_id" => 2},
      %{"type" => "attack", "target" => [0, 0], "robot_id" => 4}
    ]

    inital_game = Game.put_events(game, robot_spawns)
    after_turn = Logic.calculate_turn(inital_game, %{player_1: [], player_2: player_2_moves})

    assert %{hp: 48} = Game.get_robot(after_turn, 1)
  end

  test "Trying to attack a non adjacent square does not work", %{game: game} do
    robot_spawns = ~g/1 0
                      0 2/

    player_2_moves = [
      %{"type" => "attack", "target" => [0, 0], "robot_id" => 2}
    ]

    inital_game = Game.put_events(game, robot_spawns)
    after_turn = Logic.calculate_turn(inital_game, %{player_1: [], player_2: player_2_moves})

    assert %{hp: 50} = Game.get_robot(after_turn, 1)
  end

  test "you can't attack yourself I guess? ¯\_(ツ)_/¯", %{game: game} do
    robot_spawns = ~g/1/

    player_1_moves = [
      %{"type" => "attack", "target" => [0, 0], "robot_id" => 1}
    ]

    inital_game = Game.put_events(game, robot_spawns)
    after_turn = Logic.calculate_turn(inital_game, %{player_1: player_1_moves, player_2: []})

    assert %{hp: 50} = Game.get_robot(after_turn, 1)
  end

  test "suicide removes the robot and damages adjacent squares", %{game: game} do
    robot_spawns = ~g/1 2
                      4 6/

    player_1_moves = [
      %{"type" => "suicide", "robot_id" => 1}
    ]

    inital_game = Game.put_events(game, robot_spawns)
    after_turn = Logic.calculate_turn(inital_game, %{player_1: player_1_moves, player_2: []})

    assert nil == Game.get_robot(after_turn, 1)
    assert %{hp: 45} = Game.get_robot(after_turn, 2)
    assert %{hp: 45} = Game.get_robot(after_turn, 4)
    assert %{hp: 50} = Game.get_robot(after_turn, 6)
  end

  test "You can't move into the square of a suiciding robot", %{game: game} do
    robot_spawns = ~g/1 2/

    player_1_moves = [
      %{"type" => "suicide", "robot_id" => 1}
    ]

    player_2_moves = [
      %{"type" => "move", "target" => [0, 0], "robot_id" => 2}
    ]

    inital_game = Game.put_events(game, robot_spawns)

    after_turn =
      Logic.calculate_turn(inital_game, %{player_1: player_1_moves, player_2: player_2_moves})

    assert %{location: [0, 1]} = Game.get_robot(after_turn, 2)
  end
end
