defmodule BattleBox.Games.RobotGame.Logic do
  import BattleBox.Games.RobotGame.Game

  def calculate_turn(game, moves) do
    game =
      if spawning_round?(game),
        do: apply_events(game, generate_spawn_events(game)),
        else: game

    movements =
      for move <- moves,
          move.type == :move,
          do: move

    guard_locations =
      for move <- moves,
          move.type == :guard,
          robot = get_robot(game, move.robot_id),
          do: robot.location

    movement_events =
      for movement <- movements,
          do: generate_movement_event(game, movement, movements, guard_locations)

    game = apply_events(game, movement_events)

    events =
      moves
      |> Enum.filter(fn move -> move.type in [:suicide, :attack, :guard] end)
      |> Enum.map(fn
        %{type: :suicide} = move -> generate_suicide_event(game, move, guard_locations)
        %{type: :attack} = move -> generate_attack_event(game, move, guard_locations)
        %{type: :guard} = move -> generate_guard_event(move)
      end)

    game = apply_events(game, events)

    update_in(game.turn, &(&1 + 1))
  end

  defp generate_guard_event(move), do: %{move: move, effects: [{:guard, move.robot_id}]}

  defp generate_movement_event(game, move, movements, guard_locations) do
    effects =
      case calc_movement(game, move, movements) do
        {:move, target, robot} ->
          [{:move, robot.id, target}]

        {:no_move, reason, robot} ->
          case reason do
            :illegal_target ->
              []

            :invalid_terrain ->
              [{:damage, robot.id, collision_damage(game)}]

            :contention ->
              [{:damage, robot.id, collision_damage(game)}]

            {:collision, other_robot} ->
              other_robot_damage =
                if other_robot.location in guard_locations,
                  do: guarded_collision_damage(game),
                  else: collision_damage(game)

              [
                {:damage, robot.id, collision_damage(game)},
                {:damage, other_robot.id, other_robot_damage}
              ]
          end
      end

    %{move: move, effects: effects}
  end

  defp generate_attack_event(game, move, guard_locations) do
    robot = get_robot(game, move.robot_id)

    attack_conditions = %{
      attack_target_adjacent?: move.target in adjacent_locations(robot.location),
      guarded?: move.target in guard_locations,
      target_space_occupant: get_robot_at_location(game, move.target)
    }

    effects =
      case attack_conditions do
        %{attack_target_adjacent?: false} ->
          []

        %{target_space_occupant: nil} ->
          []

        %{target_space_occupant: other_robot, guarded?: true} when not is_nil(other_robot) ->
          [{:damage, other_robot.id, guarded_attack_damage(game)}]

        %{target_space_occupant: other_robot, guarded?: false} when not is_nil(other_robot) ->
          [{:damage, other_robot.id, attack_damage(game)}]
      end

    %{move: move, effects: effects}
  end

  defp generate_suicide_event(game, move, guard_locations) do
    robot = get_robot(game, move.robot_id)

    damage_effects =
      adjacent_locations(robot.location)
      |> Enum.map(&get_robot_at_location(game, &1))
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn %{id: affected_robot_id, location: location} ->
        damage =
          if location in guard_locations,
            do: guarded_suicide_damage(game),
            else: suicide_damage(game)

        {:damage, affected_robot_id, damage}
      end)

    %{move: move, effects: [{:remove_robot, robot.id} | damage_effects]}
  end

  defp generate_spawn_events(game) do
    spawn_locations =
      spawns(game)
      |> Enum.shuffle()
      |> Enum.take(game.spawn_per_player * 2)

    spawned_robots =
      spawn_locations
      |> Enum.zip(Stream.cycle([:player_1, :player_2]))
      |> Enum.map(fn {spawn_location, player_id} ->
        %{
          move: :spawn,
          effects: [{:create_robot, player_id, spawn_location, %{}}]
        }
      end)

    destroyed_robots =
      robots(game)
      |> Enum.filter(fn robot -> robot.location in spawn_locations end)
      |> Enum.map(fn robot ->
        %{
          move: :spawn,
          effects: [{:remove_robot, robot.id}]
        }
      end)

    destroyed_robots ++ spawned_robots
  end

  defp calc_movement(game, move, movements, stuck_robots \\ []) do
    robot = get_robot(game, move.robot_id)
    robot_currently_at_location = get_robot_at_location(game, move.target)
    moves_to_location = Enum.filter(movements, &(&1.target == move.target))

    space_info = %{
      move_target_adjacent?: move.target in adjacent_locations(robot.location),
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
      %{move_target_adjacent?: false} ->
        {:no_move, :illegal_target, robot}

      %{valid_terrain?: false} ->
        {:no_move, :invalid_terrain, robot}

      %{contention?: true} ->
        {:no_move, :contention, robot}

      %{current_occupant: other_robot, current_occupant_move: nil} when not is_nil(other_robot) ->
        {:no_move, {:collision, other_robot}, robot}

      %{current_occupant_in_stuck_robots?: true} ->
        {:move, move.target, robot}

      %{
        move_target_adjacent?: true,
        valid_terrain?: true,
        contention?: false,
        current_occupant: nil
      } ->
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
end
