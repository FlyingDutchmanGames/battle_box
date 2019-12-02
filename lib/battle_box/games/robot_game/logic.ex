defmodule BattleBox.Games.RobotGame.Logic do
  import BattleBox.Games.RobotGame.Game

  def calculate_turn(game, moves) do
    game =
      if spawning_round?(game),
        do: apply_spawn(game),
        else: game

    grouped_moves = Enum.group_by(moves, fn move -> move.type end)

    guard_locations =
      for %{robot_id: robot_id} <- grouped_moves[:guards] || [],
          %{location: location} = get_robot(game, robot_id),
          do: location

    movements = grouped_moves[:move] || []

    game =
      Enum.reduce(movements, game, fn movement, game ->
        apply_movement(game, movement.robot_id, movement.target, movements, guard_locations)
      end)

    game =
      Enum.reduce(grouped_moves[:attack] || [], game, fn attack, game ->
        apply_attack(game, attack.target, guard_locations)
      end)

    game =
      Enum.reduce(grouped_moves[:suicide] || [], game, fn suicide, game ->
        %{location: suicide_location} = get_robot(game, suicide.robot_id)
        apply_suicide(game, suicide_location, guard_locations)
      end)

    update_in(game.turn, &(&1 + 1))
  end

  def apply_movement(game, robot_id, target, _movements, _guard_locations) do
    move_robot(game, robot_id, target)
  end

  def apply_attack(game, location, guard_locations) do
    damage = get_attack_damage(game)

    damage =
      if location in guard_locations,
        do: Integer.floor_div(damage, 2),
        else: damage

    apply_damage_to_location(game, location, damage)
  end

  def apply_suicide(game, location, guard_locations) do
    damage = get_suicide_damage(game)
    game = remove_robot_at_location(game, location)

    Enum.reduce(adjacent_locations(location), game, fn loc, game ->
      damage =
        if loc in guard_locations,
          do: Integer.floor_div(damage, 2),
          else: damage

      apply_damage_to_location(game, loc, damage)
    end)
  end

  def apply_spawn(game) do
    spawn_locations =
      spawns(game)
      |> Enum.shuffle()
      |> Enum.take(game.settings.spawn_per_player * length(game.players))

    spawned_robots =
      spawn_locations
      |> Enum.zip(Stream.cycle(game.players))
      |> Enum.map(fn {spawn_location, player} ->
        %{
          player_id: player,
          location: spawn_location
        }
      end)

    destroyed_robots =
      robots(game)
      |> Enum.filter(fn robot -> robot.location in spawn_locations end)

    game
    |> remove_robots(destroyed_robots)
    |> add_robots(spawned_robots)
  end
end
