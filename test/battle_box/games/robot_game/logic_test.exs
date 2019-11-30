defmodule BattleBox.Games.RobotGame.LogicTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.{Logic, Game}

  describe "spawning_round?/1" do
    test "it knows if its a spawning round based on the turn and spawn_every param" do
      should_spawn = [
        # Spawn when the turn is a multiple of the 'spawn_every' setting
        %{turn: 10, spawn_every: 1},
        %{turn: 10, spawn_every: 2},
        %{turn: 10, spawn_every: 5},
        %{turn: 10, spawn_every: 10},
        %{turn: 20, spawn_every: 10},
        # Always spawn on the first (0th) turn
        %{turn: 0, spawn_every: 1},
        %{turn: 0, spawn_every: 2},
        %{turn: 0, spawn_every: 12_323_123_123}
      ]

      Enum.each(should_spawn, fn %{turn: turn, spawn_every: spawn_every} ->
        assert Logic.spawning_round?(game_with_turn_and_spawn_every(turn, spawn_every))
      end)

      should_not_spawn = [
        %{turn: 10, spawn_every: 3},
        %{turn: 10, spawn_every: 14},
        %{turn: 10, spawn_every: 20}
      ]

      Enum.each(should_not_spawn, fn %{turn: turn, spawn_every: spawn_every} ->
        refute Logic.spawning_round?(game_with_turn_and_spawn_every(turn, spawn_every))
      end)
    end
  end

  describe "apply_spawn/1" do
  end

  defp game_with_turn_and_spawn_every(turn, spawn_every) do
    Game.new()
    |> put_in([:settings, :spawn_every], spawn_every)
    |> put_in([:turn], turn)
  end
end
