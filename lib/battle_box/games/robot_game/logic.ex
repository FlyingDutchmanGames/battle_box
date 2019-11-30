defmodule BattleBox.Games.RobotGame.Logic do
  alias BattleBox.Games.RobotGame.Terrain

  def calculate_turn(game, valid_moves) do
    game =
      if spawning_round?(game),
        do: apply_spawn(game),
        else: game

    game
  end

  def apply_spawn(game) do
    spawn_locations =
      Terrain.spawn(game.terrain)
      |> Enum.shuffle()
      |> Enum.take(game.settings.spawn_per_player * length(game.players))

    spawned_robots =
      spawn_locations
      |> Enum.zip(Stream.cycle(game.players))
      |> Enum.map(fn {spawn_location, player} ->
        %{
          player_id: player,
          location: spawn_location,
          hp: game.settings.robot_hp,
          robot_id: Ecto.UUID.generate()
        }
      end)

    robots =
      game.robots
      |> Enum.reject(fn %{location: location} -> location in spawn_locations end)
      |> Enum.concat(spawned_robots)

    put_in(game, [:robots], robots)
  end

  def spawning_round?(%{settings: %{spawn_every: spawn_every}, turn: turn}),
    do: rem(turn, spawn_every) == 0
end
