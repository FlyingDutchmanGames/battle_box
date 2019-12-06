defmodule BattleBox.Games.RobotGame.Robot do
  defstruct [:hp, :id, :player_id, :location]

  def new(opts) do
    Map.merge(%__MODULE__{}, opts)
  end

  def apply_damage(robot, damage) do
    %__MODULE__{
      robot
      | hp: robot.hp - damage
    }
  end
end
