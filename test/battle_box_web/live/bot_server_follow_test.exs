defmodule BattleBoxWeb.BotsServerFollowTest do
  use BattleBoxWeb.ConnCase
  import Phoenix.LiveViewTest
  alias BattleBox.{GameEngine, GameEngine.BotServer, Bot, GameEngineProvider.Mock}

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

    {:ok, lobby} = robot_game_lobby(user: user, lobby_name: "LOBBY NAME")

    {:ok, bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "TEST BOT"})
      |> Repo.insert()

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

    test "if the bot gets in a game it will issue a redirect to the game",
         %{conn: conn} = context do
      {:ok, view, html} = live(conn, "/bot_servers/#{@bot_server_id}/follow")
      assert html =~ "Idle"

      {:ok, bot_server2, _} =
        GameEngine.start_bot(context.game_engine, %{
          lobby: context.lobby,
          bot: context.bot,
          connection: self()
        })

      :ok = BotServer.match_make(context.bot_server)
      :ok = BotServer.match_make(bot_server2)
      :ok = GameEngine.force_match_make(context.game_engine)
      Process.sleep(20)
      %{game_id: game_id} = GameEngine.get_bot_server(context.game_engine, @bot_server_id)
      game_url = "/games/#{game_id}?follow=#{@bot_server_id}"
      assert_redirect(view, game_url)
    end
  end
end
