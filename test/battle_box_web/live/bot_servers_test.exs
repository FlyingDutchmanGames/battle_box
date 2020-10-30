defmodule BattleBoxWeb.Live.BotServersTest do
  alias BattleBoxWeb.Live.BotServers
  use BattleBoxWeb.ConnCase
  import Phoenix.LiveViewTest
  alias BattleBox.{Arena, Bot, GameEngine, GameEngine}

  @user_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _pid} = GameEngine.start_link(name: name)
    GameEngine.Provider.set_game_engine(name)
    on_exit(fn -> GameEngine.Provider.reset!() end)
    GameEngine.names(name)
  end

  setup do
    {:ok, user} = create_user(%{user_id: @user_id})

    {:ok, arena} =
      user
      |> Ecto.build_assoc(:arenas)
      |> Arena.changeset(%{name: "test-arena", game_type: "marooned", marooned_settings: %{}})
      |> Repo.insert()

    {:ok, bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "test-bot"})
      |> Repo.insert()

    %{bot: bot, user: user, arena: arena}
  end

  test "is an empty list when there are no active servers", %{conn: conn} = context do
    {:ok, _view, html} = live_isolated(conn, BotServers, session: %{"bot" => context.bot})
    {:ok, document} = Floki.parse_document(html)
    assert [] == Floki.find(document, ".bot-server")
  end

  test "shows the active servers", %{conn: conn} = context do
    {:ok, _, _} =
      GameEngine.start_bot(context.game_engine, %{
        arena: context.arena,
        bot: context.bot,
        connection: self()
      })

    {:ok, _view, html} = live_isolated(conn, BotServers, session: %{"bot" => context.bot})
    {:ok, document} = Floki.parse_document(html)
    assert [_bot] = Floki.find(document, ".bot-server")
  end

  test "if a bot server dies, it will be removed from the page", %{conn: conn} = context do
    {:ok, bot_server_pid, _} =
      GameEngine.start_bot(context.game_engine, %{
        arena: context.arena,
        bot: context.bot,
        connection: self()
      })

    {:ok, view, html} = live_isolated(conn, BotServers, session: %{"bot" => context.bot})
    {:ok, document} = Floki.parse_document(html)
    assert [_bot] = Floki.find(document, ".bot-server")

    Process.exit(bot_server_pid, :kill)
    Process.sleep(10)

    html = render(view)
    {:ok, document} = Floki.parse_document(html)
    assert [] = Floki.find(document, ".bot-server")
  end

  test "if a bot server joins it is reflected on the page", %{conn: conn} = context do
    {:ok, view, html} = live_isolated(conn, BotServers, session: %{"bot" => context.bot})
    {:ok, document} = Floki.parse_document(html)
    assert [] = Floki.find(document, ".bot-server")

    {:ok, bot_server_pid, _} =
      GameEngine.start_bot(context.game_engine, %{
        arena: context.arena,
        bot: context.bot,
        connection: self()
      })

    Process.sleep(10)
    html = render(view)
    {:ok, document} = Floki.parse_document(html)
    assert [_bot] = Floki.find(document, ".bot-server")

    Process.exit(bot_server_pid, :kill)
    Process.sleep(10)
    html = render(view)
    {:ok, document} = Floki.parse_document(html)
    assert [] = Floki.find(document, ".bot-server")
  end
end
