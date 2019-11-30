defmodule BattleBox.Games.RobotGame.Logic do
  def calculate_turn(game, valid_moves) do
    game =
      if spawning_round?(game),
        do: apply_spawn(game),
        else: game

    game
  end

  def apply_spawn(_game) do
    raise "Not Implemented"
  end

  def spawning_round?(%{settings: %{spawn_every: spawn_every}, turn: turn}),
    do: rem(turn, spawn_every) == 0
end
