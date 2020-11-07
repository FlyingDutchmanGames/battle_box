defmodule BattleBox.GameEngineTest do
  use ExUnit.Case, async: true
  alias BattleBox.GameEngine

  test "You can start more than one so long as they have different names", %{test: name} do
    assert {:ok, pid1} = GameEngine.start_link(name: name)
    assert {:ok, pid2} = GameEngine.start_link(name: :"#{name}1")
    assert Process.alive?(pid1)
    assert Process.alive?(pid2)
  end
end
