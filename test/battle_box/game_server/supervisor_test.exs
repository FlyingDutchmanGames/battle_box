defmodule BattleBox.GameSever.GameSupervisorTest do
  alias BattleBox.GameEngine
  use ExUnit.Case, async: true

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  test "you can start the supervisor server", %{game_supervisor: game_supervisor} do
    assert Process.whereis(game_supervisor) |> Process.alive?()
  end
end
