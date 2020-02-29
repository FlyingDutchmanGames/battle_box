defmodule BattleBox.GameEngine.PlayerSever.PlayerSupervisorTest do
  alias BattleBox.GameEngine
  use ExUnit.Case, async: true

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  test "you can start the supervisor server", %{player_supervisor: player_supervisor} do
    assert Process.whereis(player_supervisor) |> Process.alive?()
  end
end
