defmodule BattleBox.MatchMakerTest do
  use ExUnit.Case, async: true
  alias BattleBox.MatchMaker
  alias BattleBox.GameServer.GameSupervisor

  setup %{test: name} do
    game_supervisor_name = Module.concat(name, GameSupervisorRegistry)
    {:ok, _} = GameSupervisor.start_link(%{name: game_supervisor_name})
    {:ok, pid} = MatchMaker.start_link(%{name: name, game_supervisor: game_supervisor_name})
    {:ok, %{pid: pid, matchmaker: name, registry: MatchMaker.registry_name(name)}}
  end

  test "you can start it", %{pid: pid} do
    assert Process.alive?(pid)
  end

  test "you can enqueue yourself", %{matchmaker: matchmaker, registry: registry} do
    me = self()

    assert [] == get_all_in_registry(registry)
    :ok = MatchMaker.join_queue("TEST LOBBY", "PLAYER_ID", matchmaker)
    assert [{"TEST LOBBY", me, %{player_id: "PLAYER_ID"}}] == get_all_in_registry(registry)
  end

  test "you can dequeue yourself", %{matchmaker: matchmaker, registry: registry} do
    me = self()

    assert [] == get_all_in_registry(registry)
    :ok = MatchMaker.join_queue("TEST LOBBY", "PLAYER_ID", matchmaker)
    assert [{"TEST LOBBY", me, %{player_id: "PLAYER_ID"}}] == get_all_in_registry(registry)
    :ok = MatchMaker.dequeue_self("TEST LOBBY", matchmaker)
    assert [] == get_all_in_registry(registry)
  end

  defp get_all_in_registry(registry) do
    Registry.select(registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end
end
