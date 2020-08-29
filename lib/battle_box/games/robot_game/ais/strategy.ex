defmodule BattleBox.Games.RobotGame.Ais.Strategy do
  defmodule Utilites do
    alias BattleBox.Utilities.{Grid, Graph}
    alias BattleBox.Games.RobotGame.Settings.Terrain

    def available_adjacent_locations(%{location: location}, terrain),
      do: available_adjacent_locations(location, terrain)

    def available_adjacent_locations([_x, _y] = location, terrain),
      do: Terrain.available_adjacent_locations(terrain, location)

    def manhattan_distance(%{location: location}, other),
      do: manhattan_distance(location, other)

    def manhattan_distance(other, %{location: location}),
      do: manhattan_distance(other, location)

    def manhattan_distance([_x1, _y1] = loc1, [_x2, _y2] = loc2),
      do: Grid.manhattan_distance(loc1, loc2)

    def towards(%{location: location}, other, terrain), do: towards(location, other, terrain)
    def towards(other, %{location: location}, terrain), do: towards(other, location, terrain)

    def towards([_x1, _y1] = loc1, [_x2, _y2] = loc2, terrain) do
      neighbors = &Terrain.available_adjacent_locations(terrain, &1)

      case Graph.a_star(loc1, loc2, neighbors, &Grid.manhattan_distance/2) do
        {:ok, [^loc1, next_loc | _]} -> next_loc
        {:ok, [^loc2]} -> loc2
        {:error, _error} -> loc1
      end
    end

    def adjacent?(%{location: location}, other), do: adjacent?(location, other)

    def adjacent?(other, %{location: location}), do: adjacent?(other, location)

    def adjacent?(loc1, loc2), do: Terrain.adjacent?(loc1, loc2)
  end

  defmodule Moves do
    def guard(%{id: robot_id}), do: %{"type" => "guard", "robot_id" => robot_id}
    def explode(%{id: robot_id}), do: %{"type" => "explode", "robot_id" => robot_id}

    def move(%{id: robot_id}, target),
      do: %{"type" => "move", "target" => target, "robot_id" => robot_id}

    def attack(%{id: robot_id}, target), do: attack(robot_id, target)
    def attack(robot_id, %{location: target}), do: attack(robot_id, target)

    def attack(robot_id, target),
      do: %{"type" => "attack", "target" => target, "robot_id" => robot_id}
  end

  defmacro __using__(_opts) do
    quote do
      import BattleBox.Games.RobotGame.Ais.Strategy.{Moves, Utilites}
      alias BattleBox.Games.RobotGame.Settings.Terrain
    end
  end
end
