defmodule BattleBox.Games.RobotGame.Logic do
  import BattleBox.Games.RobotGame.Game,
    only: [spawns: 1, robots: 1, add_robots: 2, remove_robots: 2]

  def calculate_turn(game, _valid_moves) do
    game =
      if spawning_round?(game),
        do: apply_spawn(game),
        else: game

    game
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
