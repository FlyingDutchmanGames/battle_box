defmodule BattleBox.GameEngine.BotServer.BotSupervisorTest do
  alias BattleBox.{GameEngine, ApiKey, Bot, User, GameEngine.BotServer.BotSupervisor}
  use BattleBox.DataCase, async: true

  @user_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    {:ok, user} = create_user(id: @user_id, connection_limit: 1)

    {:ok, key} =
      user
      |> Ecto.build_assoc(:api_keys)
      |> ApiKey.changeset(%{name: "test-key"})
      |> Repo.insert()

    bot =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "test-bot"})
      |> Repo.insert!()
      |> Repo.preload(:user)

    %{bot: bot, key: key, user: user}
  end

  test "you can start the bot supervisor", %{bot_supervisor: bot_supervisor} do
    assert Process.whereis(bot_supervisor) |> Process.alive?()
  end

  describe "starting a bot" do
    test "you can start a bot with a bot name and a token", context do
      assert {:ok, server, %{user_id: @user_id, bot_server_id: <<_::288>>}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 token: context.key.token,
                 bot_name: context.bot.name,
                 connection: self()
               })
    end

    test "you can start a bot", context do
      assert {:ok, server, %{user_id: @user_id, bot_server_id: <<_::288>>}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 bot: context.bot,
                 connection: self()
               })
    end

    test "starting a bot with an invalid token yields an error", context do
      assert {:error, %{token: ["Invalid API Key"]}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 token: "ABCDEF",
                 bot_name: context.bot.name,
                 connection: self()
               })
    end

    test "starting a bot when you're at your limit fails", context do
      params = %{
        token: context.key.token,
        bot_name: "whatever",
        connection: self()
      }

      assert {:ok, _pid, _params} = BotSupervisor.start_bot(context.game_engine, params)

      assert {:error, %{user: ["User connection limit exceeded"]}} =
               BotSupervisor.start_bot(context.game_engine, params)
    end

    test "starting a bot that doesn't exist creates it", context do
      assert {:ok, pid, _} =
               BotSupervisor.start_bot(context.game_engine, %{
                 token: context.key.token,
                 bot_name: "new-name",
                 connection: self()
               })

      assert %Bot{name: "new-name"} = Repo.get_by(Bot, name: "new-name")
      assert Process.alive?(pid)
    end

    test "you can't start a bot with an illegal name", context do
      assert {:error, %{name: ["should be at most 39 character(s)"]}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 token: context.key.token,
                 bot_name: :binary.copy("a", 40),
                 connection: self()
               })
    end

    test "starting a bot with a banned user fails", context do
      Repo.update_all(User, set: [is_banned: true])

      assert {:error, %{user: ["User is banned"]}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 token: context.key.token,
                 bot_name: context.bot.name,
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
                 bot: context.bot,
                 connection: self()
               })

      assert [] ==
               BotSupervisor.get_bot_servers_with_user_id(
                 context.game_engine,
                 Ecto.UUID.generate()
               )
    end

    test "getting by bot will return the bots servers for that bot", %{bot: bot} = context do
      assert {:ok, server1, %{user_id: @user_id}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 bot: bot,
                 connection: self()
               })

      assert {:ok, server2, %{user_id: @user_id}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 bot: bot,
                 connection: self()
               })

      assert [%{bot: ^bot, pid: pid1}, %{bot: ^bot, pid: pid2}] =
               BotSupervisor.get_bot_servers_with_bot_id(context.game_engine, bot.id)
               |> Enum.sort()

      assert pid1 in [server1, server2]
      assert pid2 in [server1, server2]
    end

    test "getting by user will return the bots server for a user", %{bot: bot} = context do
      assert {:ok, server1, %{user_id: @user_id}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 bot: bot,
                 connection: self()
               })

      assert {:ok, server2, %{user_id: @user_id}} =
               BotSupervisor.start_bot(context.game_engine, %{
                 bot: bot,
                 connection: self()
               })

      assert [%{bot: ^bot, pid: pid1}, %{bot: ^bot, pid: pid2}] =
               BotSupervisor.get_bot_servers_with_user_id(context.game_engine, @user_id)
               |> Enum.sort()

      assert pid1 in [server1, server2]
      assert pid2 in [server1, server2]
    end
  end
end
