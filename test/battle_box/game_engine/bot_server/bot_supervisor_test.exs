defmodule BattleBox.GameEngine.BotServer.BotSupervisorTest do
  alias BattleBox.{GameEngine, ApiKey, Bot, User, GameEngine.BotServer.BotSupervisor}
  use BattleBox.DataCase, async: true

  @user_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    {:ok, user} = create_user(id: @user_id)

    {:ok, key} =
      user
      |> Ecto.build_assoc(:api_keys)
      |> ApiKey.changeset(%{name: "TEST KEY"})
      |> Repo.insert()

    bot =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "TEST BOT"})
      |> Repo.insert!()
      |> Repo.preload(:user)

    {:ok, lobby} = robot_game_lobby(%{user: user, name: "BAR"})
    %{lobby: lobby, bot: bot, key: key, user: user}
  end

  test "you can start the supervisor server", %{bot_supervisor: bot_supervisor} do
    assert Process.whereis(bot_supervisor) |> Process.alive?()
  end

  describe "starting a bot" do
    test "you can start a bot with a bot name, lobby name, and a token", context do
      assert {:ok, server, %{user_id: @user_id, bot_server_id: <<_::288>>}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 token: context.key.token,
                 bot_name: context.bot.name,
                 lobby_name: context.lobby.name,
                 connection: self()
               })
    end

    test "you can start a bot with a bot/lobby object pair", context do
      assert {:ok, server, %{user_id: @user_id, bot_server_id: <<_::288>>}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 bot: context.bot,
                 lobby: context.lobby,
                 connection: self()
               })
    end

    test "starting a bot with an invalid token yields an error", context do
      assert {:error, %{token: ["Invalid API Key"]}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 token: "ABCDEF",
                 bot_name: context.bot.name,
                 lobby_name: context.lobby.name,
                 connection: self()
               })
    end

    test "starting a bot with an invalid lobby name yields an error", context do
      assert {:error, %{lobby: ["Lobby not found"]}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 token: context.key.token,
                 bot_name: context.bot.name,
                 lobby_name: "FAKE LOBBY",
                 connection: self()
               })
    end

    test "starting a bot with a banned user fails", context do
      {:ok, _user} = User.set_ban_status(context.user, true)

      assert {:error, %{user: ["User is banned"]}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 token: context.key.token,
                 bot_name: context.bot.name,
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
