defmodule BattleBox.GameEngine.MatchMakerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Bot, GameEngine, GameEngine.MatchMaker}

  @user_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    {:ok, user} = create_user(id: @user_id)

    {:ok, bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "FOO"})
      |> Repo.insert()

    %{bot: bot}
  end

  test "you can start it", %{match_maker: match_maker} do
    assert match_maker
           |> Process.whereis()
           |> Process.alive?()
  end

  test "you can enqueue yourself", %{bot: bot} = context do
    me = self()

    assert [] == get_all_in_registry(context.match_maker_registry)
    :ok = MatchMaker.join_queue(context.game_engine, "test-lobby", bot)

    assert [{"test-lobby", me, %{bot: bot, pid: self()}}] ==
             get_all_in_registry(context.match_maker_registry)
  end

  test "you can get all the players in a lobby", context do
    assert [] == MatchMaker.queue_for_lobby(context.game_engine, "FOO")
    :ok = MatchMaker.join_queue(context.game_engine, "FOO", context.bot)

    assert [%{bot: context.bot, pid: self(), enqueuer_pid: self()}] ==
             MatchMaker.queue_for_lobby(context.game_engine, "FOO")
  end

  test "you can get all the lobbies with queued players", context do
    assert [] == MatchMaker.lobbies_with_queued_players(context.game_engine)
    :ok = MatchMaker.join_queue(context.game_engine, "FOO", context.bot)
    :ok = MatchMaker.join_queue(context.game_engine, "BAR", context.bot)
    :ok = MatchMaker.join_queue(context.game_engine, "BAR", context.bot)
    :ok = MatchMaker.join_queue(context.game_engine, "BAZ", context.bot)

    assert Enum.sort(["BAR", "BAZ", "FOO"]) ==
             Enum.sort(MatchMaker.lobbies_with_queued_players(context.game_engine))
  end

  test "you can dequeue yourself", context do
    me = self()

    assert [] == get_all_in_registry(context.match_maker_registry)
    :ok = MatchMaker.join_queue(context.game_engine, "test-lobby", context.bot)

    assert [{"test-lobby", me, %{bot: context.bot, pid: self()}}] ==
             get_all_in_registry(context.match_maker_registry)

    :ok = MatchMaker.dequeue_self(context.game_engine, "test-lobby")
    assert [] == get_all_in_registry(context.match_maker_registry)
  end

  defp get_all_in_registry(registry) do
    Registry.select(registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end
end
