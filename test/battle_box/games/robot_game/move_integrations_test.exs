defmodule BattleBox.Games.RobotGame.MoveIntegrationTest do
  use ExUnit.Case
  alias BattleBox.Games.RobotGame.{Game, Logic}

  # 0 - Invalid
  # 1 - Normal
  # 2 - Spawn
  # 3 - Obstacle
  # ← ↑ → ↓ - Attempted move into a space, that fails and robot takes collision damage
  # ▲ ▼ ◀ ▶ - Successful move into a space
  # 🐢 - A guarding robot
  # 🤕 - A regular non guarding robot

  # test "you can move into a normal square", do: run_test("▶1")
  # test "you can move into a spawn square", do: run_test("▶2")
  # test "you can not move into an obstacle", do: run_test("→3")
  # test "you can not move into an invalid square", do: run_test("→0")
  # test "you can not move into a guarding robot", do: run_test("→🐢")
  # test "you can not move into a non guarding robot, but it will take damage", do: run_test("→🤕")
  # test "two robots can move so long as they are both moving", do: run_test("▶▶1")

  defp run_test(scenario) do
    graphs =
      scenario
      |> String.split("\n")
      |> Enum.map(&String.graphemes/1)

    graph_with_indexes =
      for {row, row_num} <- Enum.with_index(graphs),
          {col, col_num} <- Enum.with_index(row),
          do: {{row_num, col_num}, col}

    terrain = Map.new(graph_with_indexes, fn {loc, val} -> {loc, terrain_val(val)} end)

    robots =
      graph_with_indexes
      |> Enum.filter(fn {_, val} -> is_robot?(val) end)
      |> Enum.map(fn {loc, _} -> %{robot_id: robot_id(loc), player_id: "P1", location: loc} end)

    initial_game =
      Game.new(%{terrain: terrain})
      |> Game.add_robots(robots)

    moves =
      graph_with_indexes
      |> Enum.filter(fn {_, val} -> is_robot?(val) end)
      |> Enum.map(fn {location, type} -> robot_move(location, type) end)

    after_turn = Logic.calculate_turn(initial_game, moves)

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
    assert Game.get_robot(initial_game, robot_id).hp == Game.get_robot(after_turn, robot_id).hp
  end

  defp validate_collision_damage(initial_game, after_turn, robot_id) do
    assert Game.get_collision_damage(initial_game) ==
             Game.get_robot(initial_game, robot_id).hp - Game.get_robot(after_turn, robot_id).hp
  end

  defp validate_moved(initial_game, after_turn, robot_id, move_direction) do
    {x1, y1} = Game.get_robot(initial_game, robot_id).location
    {x2, y2} = Game.get_robot(after_turn, robot_id).location
    delta = {x2 - x1, y2 - y1}

    expected =
      case move_direction do
        "▲" -> {1, 0}
        "▼" -> {-1, 0}
        "▶" -> {0, 1}
        "◀" -> {0, -1}
      end

    assert delta == expected
  end

  def validate_did_not_move(initial_game, after_turn, robot_id) do
    assert Game.get_robot(initial_game, robot_id).location ==
             Game.get_robot(after_turn, robot_id).location
  end

  defp terrain_val(val) do
    case val do
      "0" -> :inaccessible
      "1" -> :normal
      "2" -> :spawn
      "3" -> :obstacle
      _ -> :normal
    end
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
      type: :guard,
      robot_id: robot_id(location)
    }

  defp move_move({row, col} = location, type) do
    target =
      case type do
        x when x in ["▲", "↑"] -> {row + 1, col}
        x when x in ["▼", "↓"] -> {row - 1, col}
        x when x in ["▶", "→"] -> {row, col + 1}
        x when x in ["◀", "←"] -> {row, col - 1}
      end

    %{
      type: :move,
      target: target,
      robot_id: robot_id(location)
    }
  end

  defp noop_move(location),
    do: %{
      type: :none,
      robot_id: robot_id(location)
    }

  defp is_robot?(val), do: val in ["▲", "▼", "◀", "▶", "←", "↑", "→", "↓", "🐢", "🤕"]

  defp robot_id({x, y}), do: "#{x}, #{y}"
end
