defmodule BattleBox.Games.RobotGame.Logic do
  import BattleBox.Games.RobotGame.EventHelpers
  import BattleBox.Games.{RobotGame, RobotGame.EventHelpers}
  alias BattleBox.Games.RobotGame.Settings.Terrain

  def calculate_turn(game, %{1 => player_1_moves, 2 => player_2_moves}) do
    moves =
      Enum.concat(
        validate_moves(game, player_1_moves, 1),
        validate_moves(game, player_2_moves, 2)
      )

    movements =
      for move <- moves,
          move["type"] == "move",
          do: move

    guard_locations =
      for move <- moves,
          move["type"] == "guard",
          robot = get_robot(game, move["robot_id"]),
          do: robot.location

    movement_events =
      for movement <- movements,
          do: generate_movement_event(game, movement, movements, guard_locations)

    game = put_events(game, movement_events)

    events =
      moves
      |> Enum.filter(fn move -> move["type"] in ["explode", "attack", "guard"] end)
      |> Enum.map(fn
        %{"type" => "explode"} = move -> generate_explode_event(game, move, guard_locations)
        %{"type" => "attack"} = move -> generate_attack_event(game, move, guard_locations)
        %{"type" => "guard"} = move -> generate_guard_event(move)
      end)

    game = put_events(game, events)

    game = if spawning_round?(game), do: do_spawn(game), else: game

    deaths = for %{id: id, hp: hp} <- robots(game), hp <= 0, do: remove_robot_effect(id)

    game =
      if deaths != [],
        do: put_event(game, %{cause: "death", effects: deaths}),
        else: game

    game =
      if over?(game),
        do: calculate_winner(game),
        else: game

    game = complete_turn(game)

    %{game: game, debug: %{}, info: %{}}
  end

  defp generate_guard_event(move), do: %{cause: move, effects: [guard_effect(move["robot_id"])]}

  defp generate_movement_event(game, move, movements, guard_locations) do
    effects =
      case calc_movement(game, move, movements) do
        {:move, [x, y], robot} ->
          [move_effect(robot.id, x, y)]

        {:no_move, reason, robot} ->
          case reason do
            :illegal_target ->
              []

            :invalid_terrain ->
              [damage_effect(robot.id, collision_damage(game))]

            :contention ->
              [damage_effect(robot.id, collision_damage(game))]

            {:collision, other_robot} ->
              other_robot_damage =
                if other_robot.location in guard_locations,
                  do: guarded_collision_damage(game),
                  else: collision_damage(game)

              [
                damage_effect(robot.id, collision_damage(game)),
                damage_effect(other_robot.id, other_robot_damage)
              ]
          end
      end

    %{cause: move, effects: effects}
  end

  defp generate_attack_event(game, move, guard_locations) do
    robot = get_robot(game, move["robot_id"])

    attack_conditions = %{
      attack_target_adjacent?:
        move["target"] in available_adjacent_locations(game, robot.location),
      guarded?: move["target"] in guard_locations,
      target_space_occupant: get_robot_at_location(game, move["target"])
    }

    effects =
      case attack_conditions do
        %{attack_target_adjacent?: false} ->
          []

        %{target_space_occupant: nil} ->
          []

        %{target_space_occupant: other_robot, guarded?: true} when not is_nil(other_robot) ->
          [damage_effect(other_robot.id, guarded_attack_damage(game))]

        %{target_space_occupant: other_robot, guarded?: false} when not is_nil(other_robot) ->
          [damage_effect(other_robot.id, attack_damage(game))]
      end

    %{cause: move, effects: effects}
  end

  defp generate_explode_event(game, move, guard_locations) do
    robot = get_robot(game, move["robot_id"])

    damage_effects =
      available_adjacent_locations(game, robot.location)
      |> Enum.map(&get_robot_at_location(game, &1))
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn %{id: affected_robot_id, location: location} ->
        damage =
          if location in guard_locations,
            do: guarded_explode_damage(game),
            else: explode_damage(game)

        damage_effect(affected_robot_id, damage)
      end)

    %{cause: move, effects: [remove_robot_effect(robot.id) | damage_effects]}
  end

  defp do_spawn(game) do
    spawn_locations =
      spawns(game)
      |> Enum.shuffle()
      |> Enum.take(game.spawn_per_player * 2)

    {game, spawned_robots} =
      spawn_locations
      |> Enum.zip(Stream.cycle([1, 2]))
      |> Enum.reduce({game, []}, fn {[x, y], player_id}, {game, spawned_robots} ->
        {game, robot_id} = next_robot_id(game)
        event = create_robot_effect(robot_id, player_id, game.robot_hp, x, y)
        {game, [event | spawned_robots]}
      end)

    destroyed_robots =
      robots(game)
      |> Enum.filter(fn robot -> robot.location in spawn_locations end)
      |> Enum.map(fn robot -> remove_robot_effect(robot.id) end)

    put_events(game, [%{cause: "spawn", effects: destroyed_robots ++ spawned_robots}])
  end

  defp calc_movement(game, move, movements, stuck_robots \\ []) do
    robot = get_robot(game, move["robot_id"])
    robot_currently_at_location = get_robot_at_location(game, move["target"])
    moves_to_location = Enum.filter(movements, &(&1["target"] == move["target"]))

    space_info = %{
      move_target_adjacent?: move["target"] in available_adjacent_locations(game, robot.location),
      valid_terrain?: Terrain.at_location(game.terrain, move["target"]) in [:normal, :spawn],
      contention?: length(moves_to_location) > 1,
      current_occupant: robot_currently_at_location,
      current_occupant_in_stuck_robots?:
        if(robot_currently_at_location, do: robot_currently_at_location.id in stuck_robots),
      current_occupant_move:
        if(robot_currently_at_location,
          do: Enum.find(movements, &(&1["robot_id"] == robot_currently_at_location.id))
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
        {:move, move["target"], robot}

      %{
        move_target_adjacent?: true,
        valid_terrain?: true,
        contention?: false,
        current_occupant: nil
      } ->
        {:move, move["target"], robot}

      %{current_occupant: other_robot, current_occupant_move: other_robot_move} ->
        case calc_movement(game, other_robot_move, movements, [robot.id | stuck_robots]) do
          {:move, _, _} ->
            {:move, move["target"], robot}

          {:no_move, _, _} ->
            {:no_move, {:collision, other_robot}, robot}
        end
    end
  end
end
