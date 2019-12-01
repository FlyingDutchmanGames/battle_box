defmodule BattleBox.Games.RobotGame.Logic do
  import BattleBox.Games.RobotGame.Game,
    only: [
      spawns: 1,
      robots: 1,
      get_robot: 2,
      add_robots: 2,
      apply_damage: 3,
      remove_robots: 2,
      get_attack_damage: 1,
      get_suicide_damage: 1,
      adjacent_locations: 1
    ]

  def calculate_turn(game, moves) do
    game =
      if spawning_round?(game),
        do: apply_spawn(game),
        else: game

    game
    |> apply_movements(moves)
    |> apply_attacks_and_suicides(moves)
    |> update_in([:round], &(&1 + 1))
  end

  def apply_movements(game, _moves) do
    game
  end

  def apply_attacks_and_suicides(game, moves) do
    moves_for_surviving_robots =
      for %{robot_id: robot_id} = move <- moves,
          %{location: actor_location} <- get_robot(game, robot_id),
          do: Map.merge(%{actor_location: actor_location}, move)

    %{
      attack: attacks,
      suicides: suicides,
      guards: guards
    } = Enum.group_by(moves_for_surviving_robots, fn move -> move.type end)

    gaurded_locations = Enum.map(guards, fn guard -> guard.actor_location end)

    attack_damages =
      attacks
      |> Enum.filter(fn %{target: target, actor_location: actor_location} ->
        target in adjacent_locations(actor_location)
      end)
      |> Enum.map(fn attack -> {attack.target, get_attack_damage(game)} end)

    suicide_damages =
      suicides
      |> Enum.flat_map(fn suicide ->
        damage = get_suicide_damage(game)

        Enum.map(adjacent_locations(suicide.actor_location), fn damage_location ->
          {damage_location, damage}
        end)
      end)

    damages = Enum.concat(attack_damages, suicide_damages)

    Enum.reduce(damages, game, fn {damage_location, damage}, game ->
      damage =
        if damage_location in gaurded_locations,
          do: damage / 2,
          else: damage

      apply_damage(game, damage_location, damage)
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

  def spawning_round?(%{settings: %{spawn_every: spawn_every}, turn: turn}),
    do: rem(turn, spawn_every) == 0
end
