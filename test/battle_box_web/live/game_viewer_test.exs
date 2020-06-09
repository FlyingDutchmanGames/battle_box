defmodule BattleBoxWeb.Live.GameViewerTest do
  use BattleBoxWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias BattleBoxWeb.Live.GameViewer

  alias BattleBox.{
    Bot,
    Repo,
    GameBot,
    Game,
    GameEngine,
    GameEngine.GameServer,
    Games.RobotGame
  }

  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  @game_id Ecto.UUID.generate()
  @user_id Ecto.UUID.generate()

  setup do
    {:ok, user} = create_user(%{user_id: @user_id})
    {:ok, lobby} = robot_game_lobby(user: user, lobby_name: "test-lobby")

    {:ok, bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "FOO"})
      |> Repo.insert()

    bot = Repo.preload(bot, :user)

    %{
      lobby: lobby,
      user: user,
      bot: bot,
      game_bots: [
        %GameBot{player: 1, bot: bot},
        %GameBot{player: 2, bot: bot}
      ]
    }
  end

  test "with a non existant ID, it renders not found", %{conn: conn} do
    id = Ecto.UUID.generate()
    {:ok, _view, html} = live_isolated(conn, GameViewer, session: %{"game_id" => id})

    assert html =~ "Game (#{id}) not found"
  end

  test "it can load a game from the database", %{conn: conn} = context do
    robot_game =
      %RobotGame{}
      |> RobotGame.complete_turn()
      |> RobotGame.complete_turn()

    {:ok, %{id: id}} =
      %Game{
        lobby: context.lobby,
        lobby_id: context.lobby.id,
        game_type: RobotGame,
        robot_game: robot_game,
        game_bots: context.game_bots
      }
      |> Repo.insert()

    {:ok, _view, html} = live_isolated(conn, GameViewer, session: %{"game_id" => id})
    assert html =~ "TURN: 1 / 100"
  end

  describe "live game watching" do
    setup %{test: name} do
      {:ok, _} = GameEngine.start_link(name: name)
      {:ok, GameEngine.names(name)}
    end

    setup %{game_engine: game_engine} do
      :ok = GameEngineProvider.set_game_engine(game_engine)
      on_exit(fn -> GameEngineProvider.reset!() end)
    end

    setup %{game_engine: game_engine, lobby: lobby, game_bots: game_bots} do
      {:ok, pid} =
        GameEngine.start_game(game_engine, %{
          players: %{
            1 => named_proxy(:player_1),
            2 => named_proxy(:player_2)
          },
          game: %Game{
            id: @game_id,
            lobby: lobby,
            lobby_id: lobby.id,
            game_bots: game_bots,
            game_type: RobotGame,
            robot_game: %RobotGame{}
          }
        })

      :ok = GameServer.accept_game(pid, 1)
      :ok = GameServer.accept_game(pid, 2)

      %{game_server: pid}
    end

    test "it can display a game in progress", %{conn: conn} do
      {:ok, _view, html} = live_isolated(conn, GameViewer, session: %{"game_id" => @game_id})
      assert html =~ "TURN: 0 / 100"
      assert html =~ "LIVE"
    end

    test "it will update when the game updates (and go to the most recent completed move)",
         %{conn: conn} = context do
      {:ok, view, html} = live_isolated(conn, GameViewer, session: %{"game_id" => @game_id})
      Process.link(view.pid)
      assert html =~ "TURN: 0 / 100"

      Enum.each(1..9, fn _ ->
        :ok = GameServer.submit_commands(context.game_server, 1, [])
        :ok = GameServer.submit_commands(context.game_server, 2, [])
      end)

      Process.sleep(10)
      assert %{"turn" => "8"} = Regex.named_captures(~r/TURN: (?<turn>\d+) \/ 100/, render(view))
    end

    test "when the game server dies, it will switch to the historical view",
         %{conn: conn} = context do
      robot_game =
        %RobotGame{}
        |> RobotGame.complete_turn()
        |> RobotGame.complete_turn()

      {:ok, _} =
        %Game{
          lobby: context.lobby,
          lobby_id: context.lobby.id,
          robot_game: robot_game,
          game_bots: context.game_bots,
          game_type: RobotGame,
          id: @game_id
        }
        |> Repo.insert()

      {:ok, view, html} = live_isolated(conn, GameViewer, session: %{"game_id" => @game_id})
      assert html =~ "LIVE"
      Process.exit(context.game_server, :kill)
      Process.sleep(10)
      assert render(view) =~ "1 minute ago"
    end

    test "when a game server dies before it is presisted it switches to crashed",
         %{conn: conn} = context do
      {:ok, view, html} = live_isolated(conn, GameViewer, session: %{"game_id" => @game_id})
      assert html =~ "LIVE"
      Process.exit(context.game_server, :kill)
      Process.sleep(10)
      assert render(view) =~ "Game (#{@game_id}) has crashed"
    end
  end

  describe "Arrow Keys let you change the turn you're viewing" do
    setup %{game_bots: game_bots} do
      robot_game =
        %RobotGame{}
        |> RobotGame.complete_turn()
        |> RobotGame.complete_turn()

      {:ok, %{id: id}} =
        %Game{robot_game: robot_game, game_bots: game_bots, game_type: RobotGame}
        |> Repo.insert()

      %{game_id: id}
    end

    test "Arrow Keys move the page around but only to extent of game", %{
      conn: conn,
      game_id: game_id
    } do
      {:ok, view, html} =
        live_isolated(conn, GameViewer, session: %{"game_id" => game_id, "turn" => "2"})

      assert html =~ "TURN: 2 / 100"
      assert render_keyup(view, "change-turn", %{"code" => "ArrowLeft"}) =~ "TURN: 1 / 100"
      assert render_keyup(view, "change-turn", %{"code" => "ArrowLeft"}) =~ "TURN: 0 / 100"
      assert render_keyup(view, "change-turn", %{"code" => "ArrowLeft"}) =~ "TURN: 0 / 100"
      assert render_keyup(view, "change-turn", %{"code" => "ArrowRight"}) =~ "TURN: 1 / 100"
      assert render_keyup(view, "change-turn", %{"code" => "ArrowRight"}) =~ "TURN: 2 / 100"
      assert render_keyup(view, "change-turn", %{"code" => "ArrowRight"}) =~ "TURN: 2 / 100"
    end

    test "other arrow keys don't break it", %{conn: conn, game_id: game_id} do
      {:ok, view, html} =
        live_isolated(conn, GameViewer, session: %{"game_id" => game_id, "turn" => "2"})

      assert html =~ "TURN: 2 / 100"
      assert render_keyup(view, "change-turn", %{"code" => "ArrowUp"}) =~ "TURN: 2 / 100"
      assert render_keyup(view, "change-turn", %{"code" => "ArrowDown"}) =~ "TURN: 2 / 100"
    end
  end
end
