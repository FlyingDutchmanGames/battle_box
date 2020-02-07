defmodule BattleBox.MatchMakerTest do
  use ExUnit.Case, async: true
  alias BattleBox.MatchMaker
  alias BattleBox.GameEngine

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  test "you can start it", %{match_maker: match_maker} do
    assert match_maker
           |> Process.whereis()
           |> Process.alive?()
  end

  test "you can enqueue yourself", names do
    me = self()

    assert [] == get_all_in_registry(names.match_maker_registry)
    :ok = MatchMaker.join_queue(names.game_engine, "TEST LOBBY", "PLAYER_ID")

    assert [{"TEST LOBBY", me, %{player_id: "PLAYER_ID", pid: self()}}] ==
             get_all_in_registry(names.match_maker_registry)
  end

  test "you can dequeue yourself", names do
    me = self()

    assert [] == get_all_in_registry(names.match_maker_registry)
    :ok = MatchMaker.join_queue(names.game_engine, "TEST LOBBY", "PLAYER_ID")

    assert [{"TEST LOBBY", me, %{player_id: "PLAYER_ID", pid: self()}}] ==
             get_all_in_registry(names.match_maker_registry)

    :ok = MatchMaker.dequeue_self(names.game_engine, "TEST LOBBY")
    assert [] == get_all_in_registry(names.match_maker_registry)
  end

  defp get_all_in_registry(registry) do
    Registry.select(registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end
end
