defmodule BattleBox.GameEngine.AiServer.AiSupervisorTest do
  use BattleBox.DataCase, async: true
  alias BattleBox.GameEngine

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  test "you can start the ai supervisor", %{ai_supervisor: ai_supervisor} do
    assert Process.whereis(ai_supervisor) |> Process.alive?
  end
end
