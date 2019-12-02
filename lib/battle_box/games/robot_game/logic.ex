defmodule BattleBox.Games.RobotGame.Logic do
  import BattleBox.Games.RobotGame.Game,
    only: [
      spawns: 1,
      robots: 1,
      add_robots: 2,
      remove_robots: 2,
      spawning_round?: 1,
      get_attack_damage: 1,
      get_suicide_damage: 1,
      adjacent_locations: 1,
      remove_robot_at_location: 2,
      apply_damage_to_location: 3
    ]

  def calculate_turn(game, _moves) do
    game =
      if spawning_round?(game),
        do: apply_spawn(game),
        else: game

    update_in(game.round, &(&1 + 1))
  end

  def apply_attack(game, location, guard_locations) do
    damage = get_attack_damage(game)

    damage =
      if location in guard_locations,
        do: damage / 2,
        else: damage

    apply_damage_to_location(game, location, damage)
  end

  def apply_suicide(game, location, guard_locations) do
    damage = get_suicide_damage(game)
    game = remove_robot_at_location(game, location)

    Enum.reduce(adjacent_locations(location), game, fn loc, game ->
      damage =
        if loc in guard_locations,
          do: damage / 2,
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
