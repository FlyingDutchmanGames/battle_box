defmodule BattleBoxWeb.Live.ScoresTest do
  use BattleBoxWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias BattleBox.{Bot, GameEngine, GameEngine.BotServer}
  alias BattleBoxWeb.Live.Scores
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
    {:ok, arena} = robot_game_arena(%{arena_name: "test-arena", user: user})

    {:ok, bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "test-bot"})
      |> Repo.insert()

    {:ok, bot_server_1, _} =
      GameEngine.start_bot(context.game_engine, %{
        bot: bot,
        connection: named_proxy(:player_1)
      })

    {:ok, bot_server_2, _} =
      GameEngine.start_bot(context.game_engine, %{
        bot: bot,
        connection: named_proxy(:player_1)
      })

    %{arena: arena, user: user, bot_server_1: bot_server_1, bot_server_2: bot_server_2}
  end

  describe "live games" do
    test "it will show live game scores in the arena", %{conn: conn} = context do
      Process.link(context.bot_server_1)
      Process.link(context.bot_server_2)

      :ok = BotServer.match_make(context.bot_server_1, context.arena)
      :ok = BotServer.match_make(context.bot_server_2, context.arena)
      :ok = GameEngine.force_match_make(context.game_engine)

      Process.sleep(100)
      {:ok, _view, html} = live_isolated(conn, Scores, session: %{"arena" => context.arena})
      {:ok, document} = Floki.parse_document(html)
      assert [_] = Floki.find(document, ".live-score-card")
    end

    test "if the game server dies it disappears from the page", %{conn: conn} = context do
      :ok = BotServer.match_make(context.bot_server_1, context.arena)
      :ok = BotServer.match_make(context.bot_server_2, context.arena)
      :ok = GameEngine.force_match_make(context.game_engine)
      Process.sleep(20)
      {:ok, view, html} = live_isolated(conn, Scores, session: %{"arena" => context.arena})
      {:ok, document} = Floki.parse_document(html)
      assert [_] = Floki.find(document, ".live-score-card")
      Process.exit(context.bot_server_1, :kill)
      Process.sleep(20)
      {:ok, document} = render(view) |> Floki.parse_document()
      assert [] == Floki.find(document, ".live-score-card")
    end

    test "it will add newly started games to the page", %{conn: conn} = context do
      {:ok, view, html} = live_isolated(conn, Scores, session: %{"arena" => context.arena})
      {:ok, document} = Floki.parse_document(html)
      assert [] == Floki.find(document, ".live-score-card")

      :ok = BotServer.match_make(context.bot_server_1, context.arena)
      :ok = BotServer.match_make(context.bot_server_2, context.arena)
      :ok = GameEngine.force_match_make(context.game_engine)

      Process.sleep(20)
      {:ok, document} = render(view) |> Floki.parse_document()
      assert [_] = Floki.find(document, ".live-score-card")
    end
  end
end
