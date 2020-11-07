defmodule BattleBoxWeb.Live.HumanPlayerTest do
  use BattleBoxWeb.ConnCase, async: false
  alias BattleBox.{Bot, GameEngine}
  alias BattleBox.Games.Marooned.Ais.WildCard
  alias BattleBoxWeb.Live.HumanPlayer
  import Phoenix.LiveViewTest

  setup %{conn: conn}, do: %{conn: signin(conn)}

  setup %{test: name} do
    {:ok, _pid} = GameEngine.start_link(name: name)
    GameEngine.Provider.set_game_engine(name)
    on_exit(fn -> GameEngine.Provider.reset!() end)
    GameEngine.names(name)
  end

  setup do
    {:ok, arena} = marooned_arena()
    %{arena: arena}
  end

  test "if there is no human server, it tells you", %{conn: conn} do
    {:ok, _view, html} =
      live_isolated(conn, HumanPlayer, session: %{"human_server_id" => Ecto.UUID.generate()})

    assert html =~ "Not Found"
  end

  test "you can connect to the UI", %{arena: arena, conn: conn, game_engine: game_engine} do
    {:ok, bot} = Bot.anon_human_bot()

    {:ok, %{human_server_id: human_server_id}} =
      GameEngine.human_vs_ai(game_engine, arena, bot, [WildCard])

    {:ok, _view, html} =
      live_isolated(conn, HumanPlayer, session: %{"human_server_id" => human_server_id})

    # TODO implement
    # assert html =~"connected"
  end

  test "if the server is already connected, it will fail", %{
    arena: arena,
    conn: conn,
    game_engine: game_engine
  } do
    {:ok, bot} = Bot.anon_human_bot()

    {:ok, %{human_server_id: human_server_id}} =
      GameEngine.human_vs_ai(game_engine, arena, bot, [WildCard])

    {:ok, _view, _html} =
      live_isolated(conn, HumanPlayer, session: %{"human_server_id" => human_server_id})

    {:ok, _view, html} =
      live_isolated(conn, HumanPlayer, session: %{"human_server_id" => human_server_id})

    assert html =~ "<h1>Already Connected</h1>"
  end
end
