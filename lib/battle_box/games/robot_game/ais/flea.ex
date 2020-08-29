defmodule BattleBox.Games.RobotGame.Ais.Flea do
  use BattleBox.Games.RobotGame.Ais.Strategy

  @closeness_threshold 5.0

  def name, do: "flea"
  def description, do: "Run for the hills! (or at least as far from these enemies as possible)"
  def difficulty, do: 3
  def creator, do: "the-notorious-gjp"

  def initialize(%{terrain_base64: base64}) do
    terrain = Base.decode64!(base64)
    %{terrain: terrain}
  end

  def commands(%{game_state: %{robots: robots}, player: player, ai_state: %{terrain: terrain}}) do
    my_robots = for robot <- robots, robot.player_id == player, do: robot
    enemies = for robot <- robots, robot.player_id != player, do: robot

    occupied_spaces = for %{location: location} <- robots, do: location

    for robot <- my_robots do
      close_enemies =
        for enemy <- enemies,
            manhattan_distance(robot, enemy) < @closeness_threshold,
            do: enemy

      target =
        [robot.location | available_adjacent_locations(robot, terrain)]
        |> Enum.max_by(fn location ->
          Enum.sum(for enemy <- close_enemies, do: manhattan_distance(location, enemy))
        end)

      move(robot, target)
    end
    |> Enum.uniq_by(& &1["target"])
    |> Enum.reject(&(&1["target"] in occupied_spaces))
  end
end
