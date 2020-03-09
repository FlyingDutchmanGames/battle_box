defmodule BattleBoxWeb.LobbyLiveTest do
  use BattleBoxWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias BattleBox.{Bot, Lobby, GameEngine, GameEngine.BotServer}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  @user_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup %{game_engine: game_engine} do
    :ok = GameEngineProvider.set_game_engine(game_engine)
    on_exit(fn -> :ok = GameEngineProvider.reset!() end)
  end

  setup context do
    {:ok, user} = create_user(user_id: @user_id)
    {:ok, lobby} = Lobby.create(%{name: "TEST LOBBY", game_type: "robot_game", user_id: @user_id})
    {:ok, bot} = Bot.create(%{user_id: @user_id, name: "TEST BOT"})

    {:ok, bot_server_1, _} =
      GameEngine.start_bot(context.game_engine, %{
        lobby: lobby,
        bot: bot,
        connection: named_proxy(:player_1)
      })

    {:ok, bot_server_2, _} =
      GameEngine.start_bot(context.game_engine, %{
        lobby: lobby,
        bot: bot,
        connection: named_proxy(:player_1)
      })

    %{lobby: lobby, user: user, bot_server_1: bot_server_1, bot_server_2: bot_server_2}
  end

  test "renders not found for a non existant lobby", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/lobbies/#{Ecto.UUID.generate()}")
    assert html =~ "Not Found"
  end

  test "it can show a lobby", %{conn: conn} = context do
    {:ok, _view, html} = live(conn, "/lobbies/#{context.lobby.id}")
    assert html =~ "#{context.user.github_login_name} / #{context.lobby.name}"
  end

  describe "live games" do
    test "it will show live games in the lobby", %{conn: conn} = context do
      :ok = BotServer.match_make(context.bot_server_1)
      :ok = BotServer.match_make(context.bot_server_2)
      :ok = GameEngine.force_match_make(context.game_engine)
      {:ok, _view, html} = live(conn, "/lobbies/#{context.lobby.id}")
      {:ok, document} = Floki.parse_document(html)
      assert [_] = Floki.find(document, ".game")
    end

    test "if the game server dies it disappears from the page", %{conn: conn} = context do
      :ok = BotServer.match_make(context.bot_server_1)
      :ok = BotServer.match_make(context.bot_server_2)
      :ok = GameEngine.force_match_make(context.game_engine)
      {:ok, view, html} = live(conn, "/lobbies/#{context.lobby.id}")
      {:ok, document} = Floki.parse_document(html)
      assert [_] = Floki.find(document, ".game")
      Process.exit(context.bot_server_1, :kill)
      Process.sleep(10)
      {:ok, document} = render(view) |> Floki.parse_document()
      assert [] == Floki.find(document, ".game")
    end
  end
end
