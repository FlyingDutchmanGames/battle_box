defmodule BattleBox.PubSubTest do
  use ExUnit.Case, async: true
  alias BattleBox.{Game, Bot, Lobby, GameEngine}

  @user_id Ecto.UUID.generate()
  @game_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _pid} = GameEngine.start_link(name: name)
    GameEngine.names(name)
  end

  setup do
    bot = %Bot{
      name: "FOO",
      user_id: @user_id
    }

    lobby = %Lobby{
      name: "FOO"
    }

    game = %Game{
      id: @game_id
    }

    %{bot: bot, lobby: lobby, game: game}
  end

  describe "user events" do
    test "you will get bot server joins for your user", context do
      bot_server_id = Ecto.UUID.generate()

      :ok =
        GameEngine.subscribe_to_user_events(context.game_engine, @user_id, [:bot_server_start])

      :ok =
        GameEngine.broadcast_bot_server_started(context.game_engine, %{
          bot: context.bot,
          lobby: context.lobby,
          bot_server_id: bot_server_id
        })

      assert_receive {:bot_server_start, ^bot_server_id}
    end

    test "you will not get events if its not a bot for your user", context do
      bot_server_id = Ecto.UUID.generate()

      :ok =
        GameEngine.subscribe_to_user_events(context.game_engine, @user_id, [:bot_server_start])

      :ok =
        GameEngine.broadcast_bot_server_started(context.game_engine, %{
          bot: %{context.bot | user_id: Ecto.UUID.generate()},
          lobby: context.lobby,
          bot_server_id: bot_server_id
        })

      refute_receive {:bot_server_start, ^bot_server_id}
    end

    test "you will not get bot_server_start updates if you do not request them", context do
      bot_server_id = Ecto.UUID.generate()

      :ok = GameEngine.subscribe_to_user_events(context.game_engine, @user_id, [])

      :ok =
        GameEngine.broadcast_bot_server_started(context.game_engine, %{
          bot: context.bot,
          lobby: context.lobby,
          bot_server_id: bot_server_id
        })

      refute_receive {:bot_server_start, ^bot_server_id}
    end
  end

  describe "game events" do
    test "if you subscribe to game events, game_update you get them", context do
      game_id = @game_id
      :ok = GameEngine.subscribe_to_game_events(context.game_engine, @game_id, [:game_update])
      :ok = GameEngine.broadcast_game_update(context.game_engine, context.game)
      assert_receive {:game_update, ^game_id}
    end
  end
end