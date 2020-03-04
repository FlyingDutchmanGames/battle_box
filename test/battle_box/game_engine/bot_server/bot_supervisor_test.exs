defmodule BattleBox.GameEngine.BotServer.BotSupervisorTest do
  alias BattleBox.{GameEngine, Bot, Lobby, GameEngine.BotServer.BotSupervisor}
  use BattleBox.DataCase, async: true

  @user_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  test "you can start the supervisor server", %{bot_supervisor: bot_supervisor} do
    assert Process.whereis(bot_supervisor) |> Process.alive?()
  end

  describe "starting a bot" do
    setup do
      {:ok, bot} = Bot.create(%{name: "FOO", user_id: @user_id})
      {:ok, lobby} = Lobby.create(%{name: "BAR", user_id: @user_id, game_type: "robot_game"})
      %{lobby: lobby, bot: bot}
    end

    test "you can start a bot with a lobby name and a token", context do
      assert {:ok, server, %{user_id: @user_id}} =
               BotSupervisor.start_bot(context.bot_supervisor, %{
                 token: context.bot.token,
                 lobby_name: context.lobby.name,
                 connection: self()
               })
    end

    test "you can start a bot with a bot/lobby object pair", context do
      assert {:ok, server, %{user_id: @user_id}} =
               BotSupervisor.start_bot(context.bot_supervisor, %{
                 bot: context.bot,
                 lobby: context.lobby,
                 connection: self()
               })
    end

    test "starting a bot with an invalid token yields an error", context do
      assert {:error, :invalid_token} =
               BotSupervisor.start_bot(context.bot_supervisor, %{
                 token: "ABCDEF",
                 lobby_name: context.lobby.name,
                 connection: self()
               })
    end

    test "starting a bot with an invalid lobby name yields an error", context do
      assert {:error, :lobby_not_found} =
               BotSupervisor.start_bot(context.bot_supervisor, %{
                 token: context.bot.token,
                 lobby_name: "FAKE LOBBY",
                 connection: self()
               })
    end
  end

  describe "getting bot servers from the registry" do
    test "if there are no bot servers that match the result is an empty list", context do
      assert [] ==
               BotSupervisor.get_bot_servers_with_user_id(
                 context.bot_registry,
                 Ecto.UUID.generate()
               )
    end
  end
end
