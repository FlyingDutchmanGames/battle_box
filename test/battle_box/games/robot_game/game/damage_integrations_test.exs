defmodule BattleBox.Games.RobotGame.DamageIntegrationTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.{RobotGame, RobotGame.Logic}
  import BattleBox.Games.RobotGame.Settings.Terrain.Helpers
  import BattleBox.Games.RobotGameTest.Helpers

  @terrain ~t/1 1
              1 1/

  setup do
    %{
      game:
        RobotGame.new(
          settings: %{
            terrain: @terrain,
            spawn_enabled: false,
            attack_damage_min: 1,
            attack_damage_max: 1,
            robot_hp: 50,
            suicide_damage_min: 5,
            suicide_damage_max: 5
          }
        )
    }
  end

  test "If a robot goes to 0 health it disappears" do
    robot_spawns = ~g/1 2/

    game =
      RobotGame.new(
        settings: %{
          terrain: @terrain,
          spawn_enabled: false,
          attack_damage_min: 50,
          attack_damage_max: 50,
          robot_hp: 50
        }
      )

    inital_game = RobotGame.put_events(game, robot_spawns) |> RobotGame.complete_turn()
    player_2_moves = [%{"type" => "attack", "target" => [0, 0], "robot_id" => 200}]

    after_turn = Logic.calculate_turn(inital_game, %{1 => [], 2 => player_2_moves})

    assert nil == RobotGame.get_robot(after_turn, 100)
  end

  test "If you attack a square a robot is in it takes damage", %{game: game} do
    robot_spawns = ~g/1 2/

    player_1_moves = [
      %{"type" => "noop", "robot_id" => 100}
    ]

    player_2_moves = [
      %{"type" => "attack", "target" => [0, 0], "robot_id" => 200}
    ]

    inital_game = RobotGame.put_events(game, robot_spawns) |> RobotGame.complete_turn()

    after_turn = Logic.calculate_turn(inital_game, %{1 => player_1_moves, 2 => player_2_moves})

    assert %{
             location: [0, 0],
             hp: 49
           } = RobotGame.get_robot(after_turn, 100)
  end

  test "If you attack a robot that moves out of a square it takes not damage", %{game: game} do
    robot_spawns = ~g/1 2/

    player_1_moves = [
      %{"type" => "move", "target" => [1, 0], "robot_id" => 100}
    ]

    player_2_moves = [
      %{"type" => "attack", "target" => [0, 0], "robot_id" => 200}
    ]

    inital_game = RobotGame.put_events(game, robot_spawns) |> RobotGame.complete_turn()

    after_turn = Logic.calculate_turn(inital_game, %{1 => player_1_moves, 2 => player_2_moves})

    assert %{
             location: [1, 0],
             hp: 50
           } = RobotGame.get_robot(after_turn, 100)
  end

  test "If you move into a square being attacked you take damage", %{game: game} do
    robot_spawns = ~g/1 0
                      0 2/

    player_1_moves = [
      %{"type" => "attack", "target" => [1, 0], "robot_id" => 100}
    ]

    player_2_moves = [
      %{"type" => "move", "target" => [1, 0], "robot_id" => 200}
    ]

    inital_game = RobotGame.put_events(game, robot_spawns) |> RobotGame.complete_turn()

    after_turn = Logic.calculate_turn(inital_game, %{1 => player_1_moves, 2 => player_2_moves})

    assert %{
             location: [1, 0],
             hp: 49
           } = RobotGame.get_robot(after_turn, 200)
  end

  test "A robot can suffer multiple attacks", %{game: game} do
    robot_spawns = ~g/1 2
                      4 0/

    player_2_moves = [
      %{"type" => "attack", "target" => [0, 0], "robot_id" => 200},
      %{"type" => "attack", "target" => [0, 0], "robot_id" => 400}
    ]

    inital_game = RobotGame.put_events(game, robot_spawns) |> RobotGame.complete_turn()

    after_turn = Logic.calculate_turn(inital_game, %{1 => [], 2 => player_2_moves})

    assert %{hp: 48} = RobotGame.get_robot(after_turn, 100)
  end

  test "Trying to attack a non adjacent square does not work", %{game: game} do
    robot_spawns = ~g/1 0
                      0 2/

    player_2_moves = [
      %{"type" => "attack", "target" => [0, 0], "robot_id" => 200}
    ]

    inital_game = RobotGame.put_events(game, robot_spawns) |> RobotGame.complete_turn()

    after_turn = Logic.calculate_turn(inital_game, %{1 => [], 2 => player_2_moves})

    assert %{hp: 50} = RobotGame.get_robot(after_turn, 100)
  end

  test "you can't attack yourself I guess? ¯\_(ツ)_/¯", %{game: game} do
    robot_spawns = ~g/1/

    player_1_moves = [
      %{"type" => "attack", "target" => [0, 0], "robot_id" => 100}
    ]

    inital_game = RobotGame.put_events(game, robot_spawns) |> RobotGame.complete_turn()

    after_turn = Logic.calculate_turn(inital_game, %{1 => player_1_moves, 2 => []})

    assert %{hp: 50} = RobotGame.get_robot(after_turn, 100)
  end

  test "suicide removes the robot and damages adjacent squares", %{game: game} do
    robot_spawns = ~g/1 2
                      4 6/

    player_1_moves = [
      %{"type" => "suicide", "robot_id" => 100}
    ]

    inital_game = RobotGame.put_events(game, robot_spawns) |> RobotGame.complete_turn()

    after_turn = Logic.calculate_turn(inital_game, %{1 => player_1_moves, 2 => []})

    assert nil == RobotGame.get_robot(after_turn, 100)
    assert %{hp: 45} = RobotGame.get_robot(after_turn, 200)
    assert %{hp: 45} = RobotGame.get_robot(after_turn, 400)
    assert %{hp: 50} = RobotGame.get_robot(after_turn, 600)
  end

  test "You can't move into the square of a suiciding robot", %{game: game} do
    robot_spawns = ~g/1 2/

    player_1_moves = [
      %{"type" => "suicide", "robot_id" => 1}
    ]

    player_2_moves = [
      %{"type" => "move", "target" => [0, 0], "robot_id" => 2}
    ]

    inital_game = RobotGame.put_events(game, robot_spawns)

    after_turn =
      Logic.calculate_turn(inital_game, %{
        1 => player_1_moves,
        2 => player_2_moves
      })

    assert %{location: [0, 1]} = RobotGame.get_robot(after_turn, 200)
  end
end
