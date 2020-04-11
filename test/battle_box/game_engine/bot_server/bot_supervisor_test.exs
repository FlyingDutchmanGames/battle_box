defmodule BattleBox.GameEngine.BotServer.BotSupervisorTest do
  alias BattleBox.{GameEngine, Bot, Lobby, GameEngine.BotServer.BotSupervisor}
  use BattleBox.DataCase, async: true

  @user_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    {:ok, bot} = Bot.create(%{name: "FOO", user_id: @user_id})
    {:ok, lobby} = Lobby.create(%{name: "BAR", user_id: @user_id, game_type: "robot_game"})
    %{lobby: lobby, bot: bot}
  end

  test "you can start the supervisor server", %{bot_supervisor: bot_supervisor} do
    assert Process.whereis(bot_supervisor) |> Process.alive?()
  end

  describe "starting a bot" do
    test "you can start a bot with a lobby name and a token", context do
      assert {:ok, server, %{user_id: @user_id}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 token: context.bot.token,
                 lobby_name: context.lobby.name,
                 connection: self()
               })
    end

    test "you can start a bot with a bot/lobby object pair", context do
      assert {:ok, server, %{user_id: @user_id}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 bot: context.bot,
                 lobby: context.lobby,
                 connection: self()
               })
    end

    test "starting a bot with an invalid token yields an error", context do
      assert {:error, :invalid_token} =
               BotSupervisor.start_bot(context.game_engine, %{
                 token: "ABCDEF",
                 lobby_name: context.lobby.name,
                 connection: self()
               })
    end

    test "starting a bot with an invalid lobby name yields an error", context do
      assert {:error, :lobby_not_found} =
               BotSupervisor.start_bot(context.game_engine, %{
                 token: context.bot.token,
                 lobby_name: "FAKE LOBBY",
                 connection: self()
               })
    end

    test "starting a bot with a banned user fails", context do
      {:ok, _user} = create_user(%{id: @user_id, is_banned: true})

      assert {:error, :banned} =
               BotSupervisor.start_bot(context.game_engine, %{
                 token: context.bot.token,
                 lobby_name: context.lobby.name,
                 connection: self()
               })
    end
  end

  describe "getting bot servers from the registry" do
    test "if there are no bot servers that match the result is an empty list", context do
      assert [] ==
               BotSupervisor.get_bot_servers_with_user_id(
                 context.game_engine,
                 Ecto.UUID.generate()
               )
    end

    test "it will not return the bots for a different user", context do
      assert {:ok, server1, %{user_id: @user_id}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 lobby: context.lobby,
                 bot: context.bot,
                 connection: self()
               })

      assert [] ==
               BotSupervisor.get_bot_servers_with_user_id(
                 context.game_engine,
                 Ecto.UUID.generate()
               )
    end

    test "getting by user will return the bots for a user", %{bot: bot, lobby: lobby} = context do
      assert {:ok, server1, %{user_id: @user_id}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 lobby: lobby,
                 bot: bot,
                 connection: self()
               })

      assert {:ok, server2, %{user_id: @user_id}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 lobby: lobby,
                 bot: bot,
                 connection: self()
               })

      assert [
               %{bot: ^bot, lobby: ^lobby, pid: pid1},
               %{bot: ^bot, lobby: ^lobby, pid: pid2}
             ] =
               BotSupervisor.get_bot_servers_with_user_id(context.game_engine, @user_id)
               |> Enum.sort()

      assert pid1 in [server1, server2]
      assert pid2 in [server1, server2]
    end
  end
end
