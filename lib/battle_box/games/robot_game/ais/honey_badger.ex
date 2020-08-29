defmodule BattleBox.Games.RobotGame.Ais.HoneyBadger do
  use BattleBox.Games.RobotGame.Ais.Strategy

  def name, do: "honey-badger"
  def description, do: "Attacks the closest enemy"
  def difficulty, do: 4
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
      adjacent_enemies = for enemy <- enemies, adjacent?(enemy, robot), do: enemy

      closest_enemy = Enum.min_by(enemies, &manhattan_distance(robot, &1), fn -> nil end)

      case %{adjacent_enemies: adjacent_enemies, closest_enemy: closest_enemy} do
        %{adjacent_enemies: [enemy | _]} ->
          attack(robot, enemy)

        %{closest_enemy: closest_enemy} when not is_nil(closest_enemy) ->
          move(robot, towards(robot, closest_enemy, terrain))

        _ ->
          guard(robot)
      end
    end
    |> Enum.group_by(& &1["type"])
    |> Enum.map(fn
      {"move", moves} ->
        moves
        |> Enum.uniq_by(& &1["target"])
        |> Enum.reject(&(&1["target"] in occupied_spaces))

      {_command, commands} ->
        commands
    end)
    |> List.flatten()
  end
end
