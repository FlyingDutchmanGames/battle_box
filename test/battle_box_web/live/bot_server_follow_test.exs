defmodule BattleBoxWeb.BotsServerFollowTest do
  use BattleBoxWeb.ConnCase
  import Phoenix.LiveViewTest
  alias BattleBox.{GameEngine, GameEngine.BotServer, Lobby, Bot, GameEngineProvider.Mock}

  @bot_server_id Ecto.UUID.generate()
  @user_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _pid} = GameEngine.start_link(name: name)
    Mock.set_game_engine(name)
    on_exit(fn -> Mock.reset!() end)
    GameEngine.names(name)
  end

  setup context do
    {:ok, user} = create_user(%{user_id: @user_id})

    {:ok, lobby} =
      Lobby.create(%{
        user_id: @user_id,
        name: "LOBBY NAME",
        game_type: "robot_game"
      })

    {:ok, bot} =
      Bot.create(%{
        user_id: @user_id,
        name: "TEST BOT"
      })

    {:ok, bot_server, _} =
      GameEngine.start_bot(context.game_engine, %{
        lobby: lobby,
        bot: bot,
        bot_server_id: @bot_server_id,
        connection: self()
      })

    %{bot: bot, user: user, lobby: lobby, bot_server: bot_server}
  end

  test "if there isn't a running bot server it returns not found", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/bot_servers/#{Ecto.UUID.generate()}/follow")
    assert html =~ "Not Found"
    assert html =~ "Probably Dead"
  end

  describe "with a bot server" do
    test "if its idle you can see it", %{conn: conn} = context do
      {:ok, _view, html} = live(conn, "/bot_servers/#{@bot_server_id}/follow")
      assert html =~ "Idle"
      assert html =~ context.bot.name
    end

    test "if the bot dies it is reflected on the page", %{conn: conn} = context do
      {:ok, view, html} = live(conn, "/bot_servers/#{@bot_server_id}/follow")
      assert html =~ "Idle"
      assert html =~ context.bot.name
      true = Process.exit(context.bot_server, :kill)
      Process.sleep(10)
      html = render(view)
      assert html =~ "Not Found"
      assert html =~ "Probably Dead"
    end

    test "the bot starting to match make is reflected", %{conn: conn} = context do
      {:ok, view, html} = live(conn, "/bot_servers/#{@bot_server_id}/follow")
      assert html =~ "Idle"
      :ok = BotServer.match_make(context.bot_server)
      Process.sleep(10)
      html = render(view)
      assert html =~ "Match Making"
    end
  end
end
