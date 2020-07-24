defmodule BattleBox.Games.RobotGame.Ais.Kansas do
  use BattleBox.Games.RobotGame.Ais.Strategy

  def name, do: "kansas"
  def description, do: "Tries its best to move to the center"
  def difficulty, do: 2
  def creator, do: "the-notorious-gjp"

  def initialize(_settings) do
    :ok
  end

  def commands(%{game_state: %{robots: robots}, player: player, settings: settings}) do
    terrain = Base.decode64!(settings.terrain_base64)
    %{rows: rows, cols: cols} = Terrain.dimensions(terrain)
    row_midpoint = Integer.floor_div(rows, 2)
    col_midpoint = Integer.floor_div(cols, 2)

    for robot <- robots, robot.player_id == player do
      [x, y] = robot.location

      target =
        cond do
          y > row_midpoint ->
            [x, y - 1]

          y < row_midpoint ->
            [x, y + 1]

          x < col_midpoint ->
            [x + 1, y]

          x > col_midpoint ->
            [x - 1, y]

          true ->
            [x + 1, y]
        end

      move(robot, target)
    end
  end
end
