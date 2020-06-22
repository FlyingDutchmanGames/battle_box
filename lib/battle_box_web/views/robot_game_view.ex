defmodule BattleBoxWeb.RobotGameView do
  use BattleBoxWeb, :view
  alias BattleBox.Games.RobotGame
  alias BattleBox.Games.RobotGame.Settings.Terrain
  alias BattleBoxWeb.Live.RobotGame.TerrainEditor

  def move_direction([x1, y1], [x2, y2]) do
    case {x2 - x1, y2 - y1} do
      {0, 1} -> :up
      {0, -1} -> :down
      {-1, 0} -> :left
      {1, 0} -> :right
    end
  end

  def terrain_number(location) do
    case location do
      [0, col] -> col
      [row, 0] -> row
      _ -> nil
    end
  end

  def robot_actions(robot_game, 0) do
    robots = RobotGame.robots_at_turn(robot_game, 0)

    Enum.map(robots, fn robot ->
      {robot, ""}
    end)
  end

  def robot_actions(robot_game, turn) do
    robots = RobotGame.robots_at_turn(robot_game, turn)

    old_locations =
      RobotGame.robots_at_turn(robot_game, turn - 1) |> index_by(& &1.id, & &1.location)

    events = get_actions(robot_game, turn) |> index_by(& &1["robot_id"])

    Enum.map(robots, fn robot ->
      old_location = Map.get(old_locations, robot.id)
      {robot, action(events, robot, old_location)}
    end)
  end

  defp get_actions(robot_game, turn) do
    robot_game
    |> RobotGame.events_for_turn(turn)
    |> Enum.flat_map(fn
      %{cause: %{"robot_id" => _} = cause} -> [cause]
      _ -> []
    end)
  end

  defp action(events, robot, old_location) do
    current_location = robot.location

    events
    |> Map.get(robot.id)
    |> case do
      nil ->
        nil

      %{"target" => ^current_location, "type" => "move"} ->
        direction = move_direction(old_location, current_location)
        {"move", direction}

      %{"target" => target, "type" => "move"} ->
        direction = move_direction(current_location, target)
        {"failed-move", direction}

      %{"target" => target, "type" => type} when type in ["attack", "move"] ->
        direction = move_direction(current_location, target)
        {type, direction}

      %{"type" => type} ->
        type
    end
  end

  defp index_by(items, fun, mapper \\ & &1) do
    Map.new(items, fn item -> {fun.(item), mapper.(item)} end)
  end
end
