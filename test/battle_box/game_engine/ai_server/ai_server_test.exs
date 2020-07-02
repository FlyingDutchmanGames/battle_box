defmodule BattleBox.GameEngine.AiServerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.GameEngine

  defmodule LogicModule do
  end

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  test "you can start the thing", context do
    {:ok, ai_server} = GameEngine.start_ai(context.game_engine, %{logic_module: LogicModule})

    assert Process.alive?(ai_server)
  end
end
