defmodule BattleBoxWeb.GameLiveTest do
  use BattleBoxWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias BattleBox.{Bot, Repo, GameBot, Game, GameEngine, GameEngine.GameServer, Games.RobotGame, Lobby}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  @game_id Ecto.UUID.generate()
  @user_id Ecto.UUID.generate()

  setup do
    {:ok, user} = create_user(%{user_id: @user_id})
    {:ok, lobby} = Lobby.create(%{name: "TEST LOBBY", game_type: RobotGame, user_id: @user_id})
    {:ok, bot} = Bot.create(%{user: user, user_id: @user_id, name: "FOO"})
    bot = Repo.preload(bot, :user)

    %{
      lobby: lobby,
      user: user,
      bot: bot,
      game_bots: [
        GameBot.new(player: "player_1", bot: bot),
        GameBot.new(player: "player_2", bot: bot)
      ]
    }
  end

  test "it can display a game off disk", %{conn: conn} = context do
    robot_game =
      RobotGame.new()
      |> RobotGame.complete_turn()
      |> RobotGame.complete_turn()

    {:ok, %{id: id}} =
      Game.new(lobby: context.lobby, robot_game: robot_game, game_bots: context.game_bots)
      |> Game.persist()

    {:ok, _view, html} = live(conn, "/games/#{id}")
    assert html =~ "TURN: 2 / 2"
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
            "player_1" => named_proxy(:player_1),
            "player_2" => named_proxy(:player_2)
          },
          game: Game.new(id: @game_id, lobby: lobby, game_bots: game_bots, robot_game: RobotGame.new())
        })

      :ok = GameServer.accept_game(pid, "player_1")
      :ok = GameServer.accept_game(pid, "player_2")

      %{game_server: pid}
    end

    test "if the game doesn't exist, its a `not_found`", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/games/#{Ecto.UUID.generate()}")
      assert html =~ "Not Found"
    end

    test "it can display a game in progress", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/games/#{@game_id}")
      assert html =~ "TURN: 0 / 0"
    end

    test "it will update when the game updates (and go to the most recent move)",
         %{conn: conn} = context do
      {:ok, view, html} = live(conn, "/games/#{@game_id}")
      Process.link(view.pid)
      assert html =~ "TURN: 0 / 0"

      Enum.each(1..9, fn _ ->
        :ok = GameServer.submit_moves(context.game_server, "player_1", [])
        :ok = GameServer.submit_moves(context.game_server, "player_2", [])
      end)

      Process.sleep(10)
      assert %{"turn" => "9"} = Regex.named_captures(~r/TURN: (?<turn>\d+) \/ 9/, render(view))
    end

    test "when the game server dies, it will switch to the historical view",
         %{conn: conn} = context do
      robot_game =
        RobotGame.new()
        |> RobotGame.complete_turn()
        |> RobotGame.complete_turn()

      {:ok, _} =
        Game.new(lobby: context.lobby, robot_game: robot_game, game_bots: context.game_bots, id: @game_id)
        |> Game.persist()

      {:ok, view, html} = live(conn, "/games/#{@game_id}")
      assert html =~ "LIVE"
      Process.exit(context.game_server, :kill)
      Process.sleep(10)
      assert render(view) =~ "1 minute ago"
    end
  end

  describe "Arrow Keys let you change the turn you're viewing" do
    setup %{game_bots: game_bots} do
      robot_game =
        RobotGame.new()
        |> RobotGame.complete_turn()
        |> RobotGame.complete_turn()

      {:ok, %{id: id}} =
        Game.new(robot_game: robot_game, game_bots: game_bots)
        |> Game.persist()

      %{game_id: id}
    end

    test "Arrow Keys move the page around but only to extent of game", %{
      conn: conn,
      game_id: game_id
    } do
      {:ok, view, html} = live(conn, "/games/#{game_id}")
      assert html =~ "TURN: 2 / 2"
      assert render_keyup(view, "change_turn", %{"code" => "ArrowLeft"}) =~ "TURN: 1 / 2"
      assert render_keyup(view, "change_turn", %{"code" => "ArrowLeft"}) =~ "TURN: 0 / 2"
      assert render_keyup(view, "change_turn", %{"code" => "ArrowLeft"}) =~ "TURN: 0 / 2"
      assert render_keyup(view, "change_turn", %{"code" => "ArrowRight"}) =~ "TURN: 1 / 2"
      assert render_keyup(view, "change_turn", %{"code" => "ArrowRight"}) =~ "TURN: 2 / 2"
      assert render_keyup(view, "change_turn", %{"code" => "ArrowRight"}) =~ "TURN: 2 / 2"
    end

    test "other arrow keys don't break it", %{conn: conn, game_id: game_id} do
      {:ok, view, html} = live(conn, "/games/#{game_id}")
      assert html =~ "TURN: 2 / 2"
      assert render_keyup(view, "change_turn", %{"code" => "ArrowUp"}) =~ "TURN: 2 / 2"
      assert render_keyup(view, "change_turn", %{"code" => "ArrowDown"}) =~ "TURN: 2 / 2"
    end
  end
end
