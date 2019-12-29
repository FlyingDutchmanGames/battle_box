defmodule BattleBox.Games.RobotGame.GameSupervisorTest do
  alias BattleBox.Games.RobotGame.GameSupervisor
  use ExUnit.Case, async: true

  test "you can start the game supervisor" do
    {:ok, pid} = GameSupervisor.start_link(name: __MODULE__)
    assert Process.alive?(pid)
  end
end
