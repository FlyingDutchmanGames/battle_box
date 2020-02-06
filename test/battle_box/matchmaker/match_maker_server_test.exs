defmodule BattleBox.MatchMakerServerTest do
  use ExUnit.Case, async: true
  alias BattleBox.{MatchMakerServer, GameServer.GameSupervisor}

  setup %{test: name} do
    registry = Module.concat(name, Registry)
    game_supervisor = Module.concat(name, GameSupervisorRegistry)

    {:ok, _} = GameSupervisor.start_link(%{name: game_supervisor})
    {:ok, _} = Registry.start_link(name: registry, keys: :duplicate)

    {:ok, pid} =
      MatchMakerServer.start_link(%{
        registry: registry,
        name: name,
        game_supervisor: game_supervisor
      })

    %{registry: registry, name: name, pid: pid}
  end

  test "you can start it", %{pid: pid} do
    assert Process.alive?(pid)
  end
end
