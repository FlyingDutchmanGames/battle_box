defmodule BattleBox.Games.RobotGame.Logic do
  import BattleBox.Games.RobotGame.Game

  def calculate_turn(game, moves) do
    game =
      if spawning_round?(game),
        do: apply_spawn(game),
        else: game

    grouped_moves = Enum.group_by(moves, fn move -> move.type end)

    guard_locations =
      for %{robot_id: robot_id} <- grouped_moves[:guard] || [],
          %{location: location} = get_robot(game, robot_id),
          do: location

    movements = grouped_moves[:move] || []

    move_results =
      Enum.map(movements, fn movement -> apply_movement(game, movement, movements) end)

    game =
      Enum.reduce(move_results, game, fn move_result, game ->
        case move_result do
          {:no_move, {:collision, reason}, robot}
          when reason in [:invalid_terrain, :multiple_attempting_to_enter] ->
            apply_damage_to_robot(game, robot.robot_id, get_collision_damage(game))

          {:no_move, {:collision, {:robot_collision, collided_robot}}, robot} ->
            game
            |> apply_damage_to_robot(robot.robot_id, get_collision_damage(game))
            |> apply_damage_to_robot(
              collided_robot.robot_id,
              if(collided_robot.location in guard_locations,
                do: 0,
                else: get_collision_damage(game)
              )
            )

          {:move, target, robot} ->
            move_robot(game, robot.robot_id, target)
        end
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

  def apply_movement(game, move, movements, stuck_robots \\ []) do
    robot = get_robot(game, move.robot_id)

    with {:valid_terrain?, true} <- {:valid_terrain?, valid_terrain?(game, move.target)},
         {:contention?, false} <-
           {:contention?, attempts_to_enter_space(movements, move.target) > 1},
         {:current_occupant, nil} <- {:current_occupant, get_robot_at_location(game, move.target)} do
      {:move, move.target, robot}
    else
      {:valid_terrain?, false} ->
        {:no_move, {:collision, :invalid_terrain}, robot}

      {:contention?, true} ->
        {:no_move, {:collision, :multiple_attempting_to_enter}, robot}

      {:current_occupant, occupying_robot} ->
        if occupying_robot in stuck_robots do
          {:move, move.target, robot}
        else
          with occupying_robot_move when not is_nil(occupying_robot_move) <-
                 Enum.find(movements, fn movement ->
                   movement.robot_id == occupying_robot.robot_id
                 end),
               {:move, _, _} <-
                 apply_movement(game, occupying_robot_move, movements, [robot | stuck_robots]) do
            {:move, move.target, robot}
          else
            _ ->
              {:no_move, {:collision, {:robot_collision, occupying_robot}}, robot}
          end
        end
    end
  end

  def attempts_to_enter_space(movements, location) do
    length(Enum.filter(movements, &(&1.target == location)))
  end

  def valid_terrain?(game, location) do
    game.terrain[location] in [:normal, :spawn]
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
      |> Enum.take(game.spawn_per_player * length(game.players))

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
