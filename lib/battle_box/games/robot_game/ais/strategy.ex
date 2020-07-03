defmodule BattleBox.Games.RobotGame.Ais.Strategy do
  defmodule Utilites do
    def manhattan_distance(%{"location" => location}, other),
      do: manhattan_distance(location, other)

    def manhattan_distance(other, %{"location" => location}),
      do: manhattan_distance(other, location)

    def manhattan_distance([x1, y1], [x2, y2]) do
      a_squared = :math.pow(x2 - x1, 2)
      b_squared = :math.pow(y2 - y1, 2)
      :math.pow(a_squared + b_squared, 0.5)
    end

    def towards(%{location: location}, other), do: towards(location, other)
    def towards(other, %{location: location}), do: towards(other, location)

    def towards([x1, y1] = _robot_loc, [x2, y2] = _target) do
      cond do
        x1 > x2 ->
          [x1 - 1, y1]

        x1 < x2 ->
          [x1 + 1, y1]

        y1 > y2 ->
          [x1, y1 - 1]

        y1 < y2 ->
          [x1, y1 + 1]
      end
    end
  end

  defmodule Moves do
    def guard(%{id: robot_id}), do: %{"type" => "guard", "robot_id" => robot_id}
    def suicide(%{id: robot_id}), do: %{"type" => "suicide", "robot_id" => robot_id}

    def move(%{id: robot_id}, target),
      do: %{"type" => "move", "target" => target, "robot_id" => robot_id}

    def attack(%{id: robot_id}, target), do: attack(robot_id, target)
    def attack(robot_id, %{"location" => target}), do: attack(robot_id, target)

    def attack(robot_id, target),
      do: %{"type" => "attack", "target" => target, "robot_id" => robot_id}
  end

  defmacro __using__(_opts) do
    quote do
      import BattleBox.Games.RobotGame.Ais.Strategy.{Moves, Utilites}
      import BattleBox.Games.RobotGame, only: [adjacent_locations: 1]
      alias BattleBox.Games.RobotGame.Settings.Terrain
    end
  end
end
