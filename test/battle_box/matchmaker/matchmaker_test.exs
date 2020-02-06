defmodule BattleBox.MatchMakerTest do
  use ExUnit.Case, async: true
  alias BattleBox.MatchMaker

  setup %{test: name} do
    {:ok, pid} = MatchMaker.start_link(name: name)
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
