defmodule BattleBox.MatchMakerTest do
  use ExUnit.Case, async: true
  alias BattleBox.MatchMaker

  test "you can start it" do
    {:ok, pid} = MatchMaker.start_link(%{})
    assert Process.alive?(pid)
  end
end
