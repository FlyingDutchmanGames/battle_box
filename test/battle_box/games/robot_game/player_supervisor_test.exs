defmodule BattleBox.Games.RobotGame.PlayerSupervisorTest do
  alias BattleBox.Games.RobotGame.PlayerSupervisor
  use ExUnit.Case, async: true

  test "you can start the player supervisor" do
    {:ok, pid} = PlayerSupervisor.start_link(name: __MODULE__)
    assert Process.alive?(pid)
  end
end
