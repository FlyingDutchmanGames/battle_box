defmodule BattleBox.MatchMakerTest do
  use ExUnit.Case, async: true
  alias BattleBox.MatchMaker
  alias BattleBox.GameEngine

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)

    {:ok,
     %{
       game_engine: name,
       matchmaker: GameEngine.matchmaker_name(name),
       registry: GameEngine.matchmaker_registry_name(name)
     }}
  end

  test "you can start it", %{matchmaker: matchmaker} do
    assert matchmaker
           |> Process.whereis()
           |> Process.alive?()
  end

  test "you can enqueue yourself", %{matchmaker: matchmaker, registry: registry} do
    me = self()

    assert [] == get_all_in_registry(registry)
    :ok = MatchMaker.join_queue(matchmaker, "TEST LOBBY", "PLAYER_ID")

    assert [{"TEST LOBBY", me, %{player_id: "PLAYER_ID", pid: self()}}] ==
             get_all_in_registry(registry)
  end

  test "you can dequeue yourself", %{matchmaker: matchmaker, registry: registry} do
    me = self()

    assert [] == get_all_in_registry(registry)
    :ok = MatchMaker.join_queue(matchmaker, "TEST LOBBY", "PLAYER_ID")

    assert [{"TEST LOBBY", me, %{player_id: "PLAYER_ID", pid: self()}}] ==
             get_all_in_registry(registry)

    :ok = MatchMaker.dequeue_self(matchmaker, "TEST LOBBY")
    assert [] == get_all_in_registry(registry)
  end

  defp get_all_in_registry(registry) do
    Registry.select(registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end
end
