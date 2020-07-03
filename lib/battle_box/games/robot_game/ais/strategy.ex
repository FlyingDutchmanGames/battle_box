defmodule BattleBox.Games.RobotGame.Ais.Strategy do
  defmodule Moves do
    def guard(%{"id" => robot_id}), do: %{"type" => "guard", "robot_id" => robot_id}
    def suicide(%{"id" => robot_id}), do: %{"type" => "suicide", "robot_id" => robot_id}

    def move(%{"id" => robot_id}, target),
      do: %{"type" => "move", "target" => target, "robot_id" => robot_id}

    def attack(%{"id" => robot_id}, target), do: attack(robot_id, target)
    def attack(robot_id, %{"location" => target}), do: attack(robot_id, target)

    def attack(robot_id, target),
      do: %{"type" => "attack", "target" => target, "robot_id" => robot_id}
  end

  defmacro __using__(_opts) do
    quote do
      import BattleBox.Games.RobotGame.Ais.Strategy.Moves
    end
  end
end
