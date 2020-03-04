defmodule BattleBox.GameEngine.BotServer.BotSupervisorTest do
  alias BattleBox.GameEngine
  use ExUnit.Case, async: true

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  test "you can start the supervisor server", %{bot_supervisor: bot_supervisor} do
    assert Process.whereis(bot_supervisor) |> Process.alive?()
  end
end
