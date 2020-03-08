defmodule BattleBoxWeb.BotsLiveTest do
  use BattleBoxWeb.ConnCase
  import Phoenix.LiveViewTest
  alias BattleBox.{Lobby, Bot, GameEngine, GameEngineProvider.Mock}

  @user_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _pid} = GameEngine.start_link(name: name)
    Mock.set_game_engine(name)
    on_exit(fn -> Mock.reset!() end)
    GameEngine.names(name)
  end

  setup do
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

    %{bot: bot, user: user, lobby: lobby}
  end

  test "with a non existant user, it returns not found", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/users/#{Ecto.UUID.generate()}/bots")
    assert html =~ "Not Found"
  end

  test "it will render a players bots", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/users/#{@user_id}/bots")
    assert html =~ "TEST BOT"
  end

  test "it will show the bot servers that a player has active", %{conn: conn} = context do
    {:ok, _, _} =
      GameEngine.start_bot(context.game_engine, %{
        lobby: context.lobby,
        bot: context.bot,
        connection: self()
      })

    {:ok, _view, html} = live(conn, "/users/#{@user_id}/bots")
    {:ok, document} = Floki.parse_document(html)
    assert [bot] = Floki.find(document, ".bot-server")
    assert Floki.text(bot) =~ "LOBBY NAME"
  end

  test "if a bot server dies it will be removed from the page", %{conn: conn} = context do
    {:ok, bot_server_pid, _} =
      GameEngine.start_bot(context.game_engine, %{
        lobby: context.lobby,
        bot: context.bot,
        connection: self()
      })

    {:ok, view, html} = live(conn, "/users/#{@user_id}/bots")
    {:ok, document} = Floki.parse_document(html)
    assert [bot] = Floki.find(document, ".bot-server")
    assert Floki.text(bot) =~ "LOBBY NAME"
    Process.exit(bot_server_pid, :kill)
    Process.sleep(10)
    html = render(view)
    {:ok, document} = Floki.parse_document(html)
    assert [] = Floki.find(document, ".bot-server")
  end

  test "if a bot server joins its reflected on the page", %{conn: conn} = context do
    {:ok, view, html} = live(conn, "/users/#{@user_id}/bots")
    {:ok, document} = Floki.parse_document(html)
    assert [] = Floki.find(document, ".bot-server")

    {:ok, bot_server_pid, _} =
      GameEngine.start_bot(context.game_engine, %{
        lobby: context.lobby,
        bot: context.bot,
        connection: self()
      })

    Process.sleep(10)
    html = render(view)
    {:ok, document} = Floki.parse_document(html)
    assert [bot] = Floki.find(document, ".bot-server")

    Process.exit(bot_server_pid, :kill)
    Process.sleep(10)
    html = render(view)
    {:ok, document} = Floki.parse_document(html)
    assert [] = Floki.find(document, ".bot-server")
  end
end
