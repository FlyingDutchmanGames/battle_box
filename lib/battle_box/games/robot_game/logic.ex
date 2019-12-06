defmodule BattleBox.Games.RobotGame.Logic do
  import BattleBox.Games.RobotGame.Game

  def calculate_turn(game, moves) do
    game =
      if spawning_round?(game),
        do: apply_spawn(game),
        else: game

    guarded_locations =
      for move <- moves,
          robot = get_robot(game, move.robot_id),
          move.type == :guard,
          do: robot.location

    movements =
      for move <- moves,
          move.type == :move,
          do: move

    game =
      Enum.reduce(movements, game, fn move, game ->
        apply_movement(game, move, movements, guarded_locations)
      end)

    game =
      Enum.reduce(moves, game, fn move, game ->
        case move.type do
          :attack -> apply_attack(game, move.target, guarded_locations)
          :suicide -> apply_suicide(game, move.robot_id, guarded_locations)
          _ -> game
        end
      end)

    update_in(game.turn, &(&1 + 1))
  end

  def apply_movement(game, move, movements, guarded_locations) do
    case calc_movement(game, move, movements) do
      {:no_move, reason, robot} ->
        case reason do
          :invalid_terrain ->
            apply_damage_to_robot(game, robot.id, collision_damage(game))

          :contention ->
            apply_damage_to_robot(game, robot.id, collision_damage(game))

          {:collision, other_robot} ->
            other_robot_damage =
              if other_robot.location in guarded_locations,
                do: guarded_collision_damage(game),
                else: collision_damage(game)

            game
            |> apply_damage_to_robot(robot.id, collision_damage(game))
            |> apply_damage_to_robot(other_robot.id, other_robot_damage)
        end

      {:move, target, robot} ->
        move_robot(game, robot.id, target)
    end
  end

  def calc_movement(game, move, movements, stuck_robots \\ []) do
    robot = get_robot(game, move.robot_id)
    robot_currently_at_location = get_robot_at_location(game, move.target)
    moves_to_location = Enum.filter(movements, &(&1.target == move.target))

    space_info = %{
      valid_terrain?: game.terrain[move.target] in [:normal, :spawn],
      contention?: length(moves_to_location) > 1,
      current_occupant: robot_currently_at_location,
      current_occupant_in_stuck_robots?:
        if(robot_currently_at_location, do: robot_currently_at_location.id in stuck_robots),
      current_occupant_move:
        if(robot_currently_at_location,
          do: Enum.find(movements, &(&1.robot_id == robot_currently_at_location.id))
        )
    }

    case space_info do
      %{valid_terrain?: false} ->
        {:no_move, :invalid_terrain, robot}

      %{contention?: true} ->
        {:no_move, :contention, robot}

      %{current_occupant: other_robot, current_occupant_move: nil} when not is_nil(other_robot) ->
        {:no_move, {:collision, other_robot}, robot}

      %{current_occupant_in_stuck_robots?: true} ->
        {:move, move.target, robot}

      %{valid_terrain?: true, contention?: false, current_occupant: nil} ->
        {:move, move.target, robot}

      %{current_occupant: other_robot, current_occupant_move: other_robot_move} ->
        case calc_movement(game, other_robot_move, movements, [robot.id | stuck_robots]) do
          {:move, _, _} ->
            {:move, move.target, robot}

          {:no_move, _, _} ->
            {:no_move, {:collision, other_robot}, robot}
        end
    end
  end

  def apply_attack(game, location, guard_locations) do
    case get_robot_at_location(game, location) do
      nil ->
        game

      robot ->
        if location in guard_locations,
          do: apply_damage_to_robot(game, robot.id, guarded_attack_damage(game)),
          else: apply_damage_to_robot(game, robot.id, attack_damage(game))
    end
  end

  def apply_suicide(game, id, guard_locations) do
    robot = get_robot(game, id)
    game = remove_robot(game, id)

    Enum.reduce(adjacent_locations(robot.location), game, fn loc, game ->
      case get_robot_at_location(game, loc) do
        nil ->
          game

        robot ->
          if loc in guard_locations,
            do: apply_damage_to_robot(game, robot.id, guarded_suicide_damage(game)),
            else: apply_damage_to_robot(game, robot.id, suicide_damage(game))
      end
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
