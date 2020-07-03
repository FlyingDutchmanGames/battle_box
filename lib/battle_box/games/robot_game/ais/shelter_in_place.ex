defmodule BattleBox.Games.RobotGame.Ais.ShelterInPlace do
  use BattleBox.Games.RobotGame.Ais.Strategy

  def name, do: "shelter-in-place"
  def description, do: "Always issues 'guard' commands to robots"

  def initialize(settings) do
    :ok
  end

  def commands(%{game_state: game_state, settings: settings, player: player}) do
    for robot <- game_state.robots,
        robot.player_id == player,
        do: guard(robot)
  end
end
