defmodule BattleBox.MatchMakerServerTest do
  use ExUnit.Case, async: true
  alias BattleBox.MatchMakerServer

  test "you can start it" do
    {:ok, pid} = MatchMakerServer.start_link(%{})
    assert Process.alive?(pid)
  end
end
