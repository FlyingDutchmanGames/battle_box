defmodule BattleBox.Games.RobotGame.MoveIntegrationTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.{RobotGame, RobotGame.Logic}
  import BattleBox.Games.RobotGame.Settings.Terrain.Helpers
  import BattleBox.Games.RobotGame.EventHelpers
  import BattleBox.Games.RobotGameTest.Helpers

  test "you can't move to a location that is not adjacent" do
    terrain = ~t/1 1
                 1 1/

    robot_spawns = ~g/0 0
                      1 0/

    game =
      RobotGame.new(settings: %{terrain: terrain, spawn_enabled: false})
      |> RobotGame.put_events(robot_spawns)

    %{game: game} =
      Logic.calculate_turn(game, %{
        1 => [%{"type" => "move", "target" => [1, 1], "robot_id" => 1}],
        2 => []
      })

    assert %{location: [0, 0]} = RobotGame.get_robot(game, 100)
  end

  # 0 - Invalid
  # 1 - Normal
  # 2 - Spawn
  # ← ↑ → ↓ - Attempted move into a space, that fails and robot takes collision damage
  # ▲ ▼ ◀ ▶ - Successful move into a space
  # 🐢 - A guarding robot
  # 🤕 - A regular non guarding robot

  test "you can move into a normal square", do: run_test("▶1")
  test "you can move into a spawn square", do: run_test("▶2")
  test "you can not move into a guarding robot", do: run_test("→🐢")
  test "you can not move into a non guarding robot, but it will take damage", do: run_test("→🤕")
  test "two robots can't move into the same square", do: run_test("→1←")
  test "two robots can move so long as they are both moving", do: run_test("▶▶1")
  test "many robots can move so long as they are both moving", do: run_test("▶▶▶▶▶▶▶▶▶▶▶▶1")
  test "A train of robots can fail to move if the front fails to move", do: run_test("→→0")

  test "A large train of robots can fail to move if the front fails to move",
    do: run_test("→→→→→→0")

  test "Two robots can swap places", do: run_test("▶◀")

  test "A clock rotation can be made",
    do:
      run_test("""
      ▶▼
      ▲◀   
      """)

  test "A long train of moves works",
    do:
      run_test("""
        ▶▶▶▶▶▶▶▶▶▶▶▶▼
        ▲◀◀◀◀◀◀◀◀◀◀◀◀    
      """)

  test "train collision", do: run_test("→→←←")

  defp run_test(scenario) do
    graphs =
      scenario
      |> String.split("\n")
      |> Enum.map(&String.graphemes/1)
      |> Enum.map(&Enum.reject(&1, fn grapheme -> String.trim(grapheme) == "" end))
      |> Enum.reject(fn line -> line == [] end)
      |> Enum.reverse()

    rows = length(graphs)
    [cols] = Enum.uniq(for row <- graphs, do: length(row))

    graph_with_indexes =
      for {row, y} <- Enum.with_index(graphs),
          {value, x} <- Enum.with_index(row),
          do: {[x, y], value}

    terrain_header = <<rows::8, cols::8>>

    terrain_data =
      graphs
      |> List.flatten()
      |> Enum.map(fn
        "0" -> 0
        "1" -> 1
        "2" -> 2
        "3" -> 3
        _ -> 1
      end)
      |> Enum.map(&<<&1::8>>)

    terrain = IO.iodata_to_binary([terrain_header, terrain_data])

    robot_spawns =
      graph_with_indexes
      |> Enum.filter(fn {_, val} -> is_robot?(val) end)
      |> Enum.map(fn {[x, y], _} ->
        id = robot_id([x, y])
        create_robot_effect(id, 1, 50, x, y)
      end)
      |> Enum.map(fn effect -> %{effects: [effect]} end)

    initial_game =
      RobotGame.new(settings: %{terrain: terrain, spawn_enabled: false})
      |> RobotGame.put_events(robot_spawns)
      |> RobotGame.complete_turn()

    moves =
      graph_with_indexes
      |> Enum.filter(fn {_, val} -> is_robot?(val) end)
      |> Enum.map(fn {location, type} -> robot_move(location, type) end)

    %{game: after_turn} = Logic.calculate_turn(initial_game, %{1 => moves, 2 => []})

    graph_with_indexes
    |> Enum.filter(fn {_, val} -> is_robot?(val) end)
    |> Enum.each(fn {location, type} ->
      case type do
        "🐢" ->
          validate_no_damage(initial_game, after_turn, robot_id(location))

        "🤕" ->
          validate_collision_damage(initial_game, after_turn, robot_id(location))

        move_direction when move_direction in ["▲", "▼", "◀", "▶"] ->
          validate_moved(initial_game, after_turn, robot_id(location), move_direction)

        x when x in ["←", "↑", "→", "↓"] ->
          validate_did_not_move(initial_game, after_turn, robot_id(location))
          validate_collision_damage(initial_game, after_turn, robot_id(location))
      end
    end)
  end

  defp validate_no_damage(initial_game, after_turn, robot_id) do
    assert RobotGame.get_robot(initial_game, robot_id).hp ==
             RobotGame.get_robot(after_turn, robot_id).hp
  end

  defp validate_collision_damage(initial_game, after_turn, robot_id) do
    damage =
      RobotGame.get_robot(initial_game, robot_id).hp -
        RobotGame.get_robot(after_turn, robot_id).hp

    assert damage > 0 && rem(damage, RobotGame.collision_damage(initial_game)) == 0
  end

  defp validate_moved(initial_game, after_turn, robot_id, move_direction) do
    [x1, y1] = RobotGame.get_robot(initial_game, robot_id).location
    [x2, y2] = RobotGame.get_robot(after_turn, robot_id).location
    delta = {x2 - x1, y2 - y1}

    expected =
      case move_direction do
        "▲" -> {0, 1}
        "▼" -> {0, -1}
        "▶" -> {1, 0}
        "◀" -> {-1, 0}
      end

    assert delta == expected
  end

  def validate_did_not_move(initial_game, after_turn, robot_id) do
    assert RobotGame.get_robot(initial_game, robot_id).location ==
             RobotGame.get_robot(after_turn, robot_id).location
  end

  defp robot_move(location, type) do
    case type do
      "🐢" ->
        guard_move(location)

      "🤕" ->
        noop_move(location)

      move when move in ["▲", "▼", "◀", "▶", "←", "↑", "→", "↓"] ->
        move_move(location, type)
    end
  end

  defp guard_move(location),
    do: %{
      "type" => "guard",
      "robot_id" => robot_id(location)
    }

  defp move_move([x, y] = location, type) do
    target =
      case type do
        t when t in ["▲", "↑"] -> [x, y + 1]
        t when t in ["▼", "↓"] -> [x, y - 1]
        t when t in ["▶", "→"] -> [x + 1, y]
        t when t in ["◀", "←"] -> [x - 1, y]
      end

    %{
      "type" => "move",
      "target" => target,
      "robot_id" => robot_id(location)
    }
  end

  defp noop_move(location),
    do: %{
      "type" => "noop",
      "robot_id" => robot_id(location)
    }

  defp is_robot?(val), do: val in ["▲", "▼", "◀", "▶", "←", "↑", "→", "↓", "🐢", "🤕"]

  defp robot_id([x, y]) do
    <<id::16>> = <<x::8, y::8>>
    id
  end
end
