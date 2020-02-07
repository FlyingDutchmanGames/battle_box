defmodule BattleBox.GameSever.GameSupervisorTest do
  alias BattleBox.GameServer.GameSupervisor
  use ExUnit.Case, async: true

  test "you can start the supervisor server" do
    {:ok, pid} = GameSupervisor.start_link(%{name: __MODULE__})
    assert Process.alive?(pid)
  end
end
