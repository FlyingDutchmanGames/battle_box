defmodule BattleBox.Games.RobotGame.Ais.ShelterInPlace do
  use BattleBox.Games.RobotGame.Ais.Strategy

  def name, do: "shelter-in-place"
  def description, do: "Always issues 'guard' commands to robots"
  def creator, do: "the-notorious-gjp"
  def difficulty, do: 1

  def initialize(_settings) do
    :ok
  end

  def commands(%{game_state: game_state, player: player}) do
    for robot <- game_state.robots,
        robot.player_id == player,
        do: guard(robot)
  end
end
