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

  test "if you try to subscribe to a non existant event you fail", context do
    assert_raise(ArgumentError, fn ->
      :ok = GameEngine.subscribe_to_game_events(context.game_engine, @game_id, [:fake_event])
    end)
  end

  describe "game events" do
    test "you can subscribe to game events", context do
      :ok = GameEngine.subscribe_to_game_events(context.game_engine, "*", [:game_update])
      :ok = GameEngine.subscribe_to_game_events(context.game_engine, @game_id, [:game_update])

      :ok =
        GameEngine.subscribe_to_arena_events(context.game_engine, @arena_id, [
          :game_start,
          :game_update
        ])

      :ok =
        GameEngine.subscribe_to_user_events(context.game_engine, @user_id, [
          :game_start,
          :game_update
        ])

      Process.sleep(10)
      :ok = GameEngine.broadcast_game_start(context.game_engine, context.game)
      :ok = GameEngine.broadcast_game_update(context.game_engine, context.game)

      assert_receive {{:game, "*"}, :game_update, @game_id}
      assert_receive {{:game, @game_id}, :game_update, @game_id}

      assert_receive {{:user, @user_id}, :game_start, @game_id}
      assert_receive {{:user, @user_id}, :game_update, @game_id}

      assert_receive {{:arena, @arena_id}, :game_start, @game_id}
      assert_receive {{:arena, @arena_id}, :game_update, @game_id}
    end

    test "game_start event works", context do
      :ok = GameEngine.subscribe_to_bot_events(context.game_engine, @bot_id, [:game_start])
      :ok = GameEngine.subscribe_to_user_events(context.game_engine, @user_id, [:game_start])
      :ok = GameEngine.subscribe_to_arena_events(context.game_engine, @arena_id, [:game_start])

      Process.sleep(10)
      GameEngine.broadcast_game_start(context.game_engine, context.game)
      assert_receive {{:bot, @bot_id}, :game_start, @game_id}
      assert_receive {{:user, @user_id}, :game_start, @game_id}
      assert_receive {{:arena, @arena_id}, :game_start, @game_id}
    end
  end

  describe "bot server events" do
    test "you can subscribe to bot server events", context do
      :ok =
        GameEngine.subscribe_to_bot_server_events(context.game_engine, @bot_server_id, [
          :bot_server_update
        ])

      :ok =
        GameEngine.subscribe_to_user_events(context.game_engine, @user_id, [
          :bot_server_start,
          :bot_server_update
        ])

      :ok =
        GameEngine.subscribe_to_bot_events(context.game_engine, @bot_id, [
          :bot_server_start,
          :bot_server_update
        ])

      :ok =
        GameEngine.subscribe_to_arena_events(context.game_engine, @arena_id, [
          :bot_server_start,
          :bot_server_update
        ])

      Process.sleep(10)
      GameEngine.broadcast_bot_server_start(context.game_engine, context.bot_server)
      GameEngine.broadcast_bot_server_update(context.game_engine, context.bot_server)

      assert_receive {{:bot_server, @bot_server_id}, :bot_server_update, @bot_server_id}
      assert_receive {{:bot, @bot_id}, :bot_server_start, @bot_server_id}
      assert_receive {{:bot, @bot_id}, :bot_server_update, @bot_server_id}
      assert_receive {{:user, @user_id}, :bot_server_start, @bot_server_id}
      assert_receive {{:user, @user_id}, :bot_server_update, @bot_server_id}
      assert_receive {{:arena, @arena_id}, :bot_server_start, @bot_server_id}
      assert_receive {{:arena, @arena_id}, :bot_server_update, @bot_server_id}
    end
  end
end
