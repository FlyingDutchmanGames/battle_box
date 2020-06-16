defmodule BattleBox.PubSubTest do
  use ExUnit.Case, async: true
  alias BattleBox.{Game, Bot, Arena, GameEngine}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 2]

  @bot_id Ecto.UUID.generate()
  @user_id Ecto.UUID.generate()
  @game_id Ecto.UUID.generate()
  @arena_id Ecto.UUID.generate()
  @bot_server_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _pid} = GameEngine.start_link(name: name)
    GameEngine.names(name)
  end

  setup do
    bot = %Bot{
      id: @bot_id,
      name: "FOO",
      user_id: @user_id
    }

    arena = %Arena{
      id: @arena_id,
      name: "FOO"
    }

    game = %Game{
      id: @game_id,
      arena_id: @arena_id,
      game_bots: [%{bot: %{id: @bot_id, user_id: @user_id}}]
    }

    bot_server = %{
      bot_server_id: @bot_server_id,
      arena: arena,
      bot: bot
    }

    %{bot: bot, arena: arena, game: game, bot_server: bot_server}
  end

  describe "user events" do
    test "you will get bot server joins for your user", context do
      bot_server_id = Ecto.UUID.generate()

      :ok =
        GameEngine.subscribe_to_user_events(context.game_engine, @user_id, [:bot_server_start])

      :ok =
        GameEngine.broadcast_bot_server_start(context.game_engine, %{
          bot: context.bot,
          arena: context.arena,
          bot_server_id: bot_server_id
        })

      assert_receive {{:user, @user_id}, :bot_server_start, ^bot_server_id}
    end

    test "you will not get events if its not a bot for your user", context do
      bot_server_id = Ecto.UUID.generate()

      :ok =
        GameEngine.subscribe_to_user_events(context.game_engine, @user_id, [:bot_server_start])

      :ok =
        GameEngine.broadcast_bot_server_start(context.game_engine, %{
          bot: %{context.bot | user_id: Ecto.UUID.generate()},
          arena: context.arena,
          bot_server_id: bot_server_id
        })

      refute_receive {{:user, @user_id}, :bot_server_start, ^bot_server_id}
    end

    test "you will not get bot_server_start updates if you do not request them", context do
      bot_server_id = Ecto.UUID.generate()

      :ok = GameEngine.subscribe_to_user_events(context.game_engine, @user_id, [])

      :ok =
        GameEngine.broadcast_bot_server_start(context.game_engine, %{
          bot: context.bot,
          arena: context.arena,
          bot_server_id: bot_server_id
        })

      refute_receive _
    end
  end

  describe "game events" do
    test "if you subscribe to game events, game_update you get them", context do
      named_proxy(:game_update_listener, fn ->
        :ok = GameEngine.subscribe_to_game_events(context.game_engine, @game_id, [:game_update])
      end)

      named_proxy(:arena_update_listener, fn ->
        :ok = GameEngine.subscribe_to_arena_events(context.game_engine, @arena_id, [:game_update])
      end)

      Process.sleep(10)
      :ok = GameEngine.broadcast_game_update(context.game_engine, context.game)
      assert_receive {:game_update_listener, {{:game, @game_id}, :game_update, @game_id}}
      assert_receive {:arena_update_listener, {{:arena, @arena_id}, :game_update, @game_id}}
    end

    test "game_start event works", context do
      :ok = GameEngine.subscribe_to_arena_events(context.game_engine, @arena_id, [:game_start])
      :ok = GameEngine.subscribe_to_user_events(context.game_engine, @user_id, [:game_start])
      :ok = GameEngine.subscribe_to_bot_events(context.game_engine, @bot_id, [:game_start])
      GameEngine.broadcast_game_start(context.game_engine, context.game)
      assert_receive {{:arena, @arena_id}, :game_start, @game_id}
      assert_receive {{:user, @user_id}, :game_start, @game_id}
      assert_receive {{:bot, @bot_id}, :game_start, @game_id}
    end
  end

  describe "bot server events" do
    test "you can subscribe to bot server events", context do
      named_proxy(:bot_server_update_listener, fn ->
        :ok =
          GameEngine.subscribe_to_bot_server_events(context.game_engine, @bot_server_id, [
            :bot_server_update
          ])
      end)

      Process.sleep(10)
      GameEngine.broadcast_bot_server_update(context.game_engine, context.bot_server)

      assert_receive {:bot_server_update_listener,
                      {{:bot_server, @bot_server_id}, :bot_server_update, @bot_server_id}}
    end
  end

  describe "bot events" do
    test "you can subscribe to a bot server start/update for that bot", context do
      named_proxy(:listener, fn ->
        :ok =
          GameEngine.subscribe_to_bot_events(context.game_engine, @bot_id, [
            :bot_server_start,
            :bot_server_update
          ])
      end)

      Process.sleep(10)
      GameEngine.broadcast_bot_server_start(context.game_engine, context.bot_server)
      assert_receive {:listener, {{:bot, @bot_id}, :bot_server_start, @bot_server_id}}
      GameEngine.broadcast_bot_server_update(context.game_engine, context.bot_server)
      assert_receive {:listener, {{:bot, @bot_id}, :bot_server_update, @bot_server_id}}
    end
  end
end
