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

    assert [] ==
             Registry.select(registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])

    :ok = MatchMaker.join_queue("TEST LOBBY", "PLAYER_ID", matchmaker)

    assert [{"TEST LOBBY", me, %{player_id: "PLAYER_ID"}}] ==
             Registry.select(registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end

  test "you can dequeue yourself", %{matchmaker: matchmaker, registry: registry} do
    me = self()

    assert [] ==
             Registry.select(registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])

    :ok = MatchMaker.join_queue("TEST LOBBY", "PLAYER_ID", matchmaker)

    assert [{"TEST LOBBY", me, %{player_id: "PLAYER_ID"}}] ==
             Registry.select(registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])

    :ok = MatchMaker.dequeue_self("TEST LOBBY", matchmaker)

    assert [] ==
             Registry.select(registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end
end
