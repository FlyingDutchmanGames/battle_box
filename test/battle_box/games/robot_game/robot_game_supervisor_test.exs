defmodule BattleBox.Games.RobotGame.RobotGameSupervisorTest do
  alias BattleBox.Games.RobotGame.RobotGameSupervisor
  use ExUnit.Case, async: true

  test "you can start the robot game supervisor" do
    {:ok, pid} = RobotGameSupervisor.start_link(name: __MODULE__)
    assert Process.alive?(pid)
  end
end
