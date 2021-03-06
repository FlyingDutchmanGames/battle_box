defmodule BattleBox.GameEngine.MatchMakerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{GameEngine, Repo}
  alias BattleBox.GameEngine.Message.GameRequest
  alias BattleBox.Games.Marooned.Ais.WildCard

  @user_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    {:ok, user} = create_user(id: @user_id)
    {:ok, bot} = create_bot(%{user: user, bot_name: "FOO"})

    bot = Repo.preload(bot, :user)

    %{bot: bot}
  end

  test "you can start it", %{match_maker: match_maker} do
    assert match_maker
           |> Process.whereis()
           |> Process.alive?()
  end

  describe "human_vs_ai/4" do
    setup do
      {:ok, arena} = marooned_arena()
      %{arena: arena}
    end

    test "You can start a game against ais", %{game_engine: game_engine, arena: arena, bot: bot} do
      {:ok, %{game_id: game_id, human_server_id: human_server_id}} =
        GameEngine.human_vs_ai(game_engine, arena, bot, [WildCard])

      assert %{human_server_id: ^human_server_id} =
               GameEngine.get_human_server(game_engine, human_server_id)

      assert %{game_id: ^game_id} = GameEngine.get_game_server(game_engine, game_id)
    end
  end

  describe "practice match" do
    setup do
      {:ok, arena} = marooned_arena()
      %{arena: arena}
    end

    test "You can start a practice match", context do
      assert {:ok, %{game_id: game_id}} =
               GameEngine.practice_match(
                 context.game_engine,
                 context.arena,
                 context.bot,
                 "wild-card"
               )

      assert_receive %GameRequest{game_id: ^game_id}
    end

    test "you can start a practice match if you match more than one bot", context do
      assert {:ok, %{game_id: game_id}} =
               GameEngine.practice_match(
                 context.game_engine,
                 context.arena,
                 context.bot,
                 %{"difficulty" => %{"min" => 1}}
               )

      assert_receive %GameRequest{game_id: ^game_id}
    end

    test "You get an error if you ask for a nonsense opponent", context do
      assert {:error, :no_opponent_matching} ==
               GameEngine.practice_match(
                 context.game_engine,
                 context.arena,
                 context.bot,
                 "fake-bot"
               )
    end
  end

  test "you can enqueue yourself", %{bot: bot} = context do
    me = self()

    assert [] == get_all_in_registry(context.match_maker_registry)
    :ok = GameEngine.join_queue(context.game_engine, "test-arena", bot)

    assert [{"test-arena", me, %{bot: bot, pid: self()}}] ==
             get_all_in_registry(context.match_maker_registry)
  end

  test "you can get all the players in a arena", context do
    assert [] == GameEngine.queue_for_arena(context.game_engine, "FOO")
    :ok = GameEngine.join_queue(context.game_engine, "FOO", context.bot)

    assert [%{bot: context.bot, pid: self(), enqueuer_pid: self()}] ==
             GameEngine.queue_for_arena(context.game_engine, "FOO")
  end

  test "you can get all the arenas with queued players", context do
    assert [] == GameEngine.arenas_with_queued_players(context.game_engine)
    :ok = GameEngine.join_queue(context.game_engine, "FOO", context.bot)
    :ok = GameEngine.join_queue(context.game_engine, "BAR", context.bot)
    :ok = GameEngine.join_queue(context.game_engine, "BAR", context.bot)
    :ok = GameEngine.join_queue(context.game_engine, "BAZ", context.bot)

    assert Enum.sort(["BAR", "BAZ", "FOO"]) ==
             Enum.sort(GameEngine.arenas_with_queued_players(context.game_engine))
  end

  test "you can dequeue yourself", context do
    me = self()

    assert [] == get_all_in_registry(context.match_maker_registry)
    :ok = GameEngine.join_queue(context.game_engine, "test-arena", context.bot)

    assert [{"test-arena", me, %{bot: context.bot, pid: self()}}] ==
             get_all_in_registry(context.match_maker_registry)

    :ok = GameEngine.dequeue_self(context.game_engine, "test-arena")
    assert [] == get_all_in_registry(context.match_maker_registry)
  end

  defp get_all_in_registry(registry) do
    Registry.select(registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end
end
