defmodule BattleBox.Games.Marooned.HelpersTest do
  use ExUnit.Case, async: true

  import BattleBox.Games.Marooned.Helpers

  test "its an error not to have both players on the board" do
    assert_raise(RuntimeError, fn ->
      ~m/0 0 0
         0 0 0
         0 0 0/
    end)
  end
end
