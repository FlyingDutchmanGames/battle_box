defmodule BattleBox.Games.RobotGame.PlayerServerTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.PlayerServer

  test "you can start it" do
    {:ok, pid} = PlayerServer.start_link(%{connection: self()})

    assert Process.alive?(pid)
  end

  test "starting it will cause the options to be sent to the connection" do
    {:ok, _pid} = PlayerServer.start_link(%{connection: self()})

    assert_receive {:options, [:matchmaking]}
  end

  test "You can tell the server to start matchmaking" do
    {:ok, pid} = PlayerServer.start_link(%{connection: self()})

    assert_receive {:options, [:matchmaking]}
    assert :ok = PlayerServer.request_matchmaking(pid)
  end
end
