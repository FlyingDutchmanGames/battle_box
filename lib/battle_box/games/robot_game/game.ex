defmodule BattleBox.Games.RobotGame.Game do
  alias BattleBox.Games.RobotGame.Terrain

  def new() do
    %{
      terrain: Terrain.default(),
      robots: [],
      turn: 0,
      settings: %{
        spawn_every: 10,
        spawn_per_player: 5,
        robot_hp: 50,
        attack_range: %{min: 8, max: 10},
        collision_damage: 5,
        suicide_damage: 15,
        max_turns: 100
      },
      players: ["player_1", "player_2"]
    }
  end

  def spawns(game), do: Terrain.spawn(game.terrain)

  def robots(game), do: game.robots

  def add_robots(game, robots), do: Enum.reduce(robots, game, &add_robot(&2, &1))

  def add_robot(game, %{player_id: _, location: _} = robot) do
    default_robot_settings = %{
      hp: game.settings.robot_hp,
      robot_id: Ecto.UUID.generate()
    }

    robot = Map.merge(default_robot_settings, robot)

    update_in(game, [:robots], fn robots -> [robot | robots] end)
  end

  def remove_robots(game, robot_ids), do: Enum.reduce(robot_ids, game, &remove_robot(&2, &1))

  def remove_robot(game, %{robot_id: robot_id}), do: remove_robot(game, robot_id)

  def remove_robot(game, robot_id),
    do: update_in(game.robots, &Enum.reject(&1, fn robot -> robot.robot_id == robot_id end))
end
