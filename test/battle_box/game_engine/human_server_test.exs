defmodule BattleBox.GameEngine.HumanServerTest do
  use ExUnit.Case, async: true
  use BattleBox.DataCase, async: false
  alias BattleBox.GameEngine

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  test "you can start the thing", context do
    opts = %{}
    {:ok, human_server, _meta} = GameEngine.start_human(context.game_engine, opts)
    assert Process.alive?(human_server)
  end
end
