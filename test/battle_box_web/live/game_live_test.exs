defmodule BattleBoxWeb.GameLiveTest do
  use BattleBoxWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias BattleBox.{GameEngine, GameServer, Games.RobotGame.Game}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  @player_1 Ecto.UUID.generate()
  @player_2 Ecto.UUID.generate()
  @game_id Ecto.UUID.generate()

  test "it can display a game off disk", %{conn: conn} = context do
    id = Ecto.UUID.generate()

    {:ok, _} =
      Game.persist(
        Game.new(%{
          player_1: @player_1,
          player_2: @player_2,
          id: id
        })
      )

    {:ok, _view, html} = live(conn, "/games/#{id}")
    assert html =~ "TURN: 0 / 100"
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

    setup %{game_engine: game_engine} do
      {:ok, pid} =
        GameEngine.start_game(game_engine, %{
          player_1: named_proxy(:player_1),
          player_2: named_proxy(:player_2),
          game: Game.new(player_1: @player_1, player_2: @player_2, id: @game_id)
        })

      :ok = GameServer.accept_game(pid, :player_1)
      :ok = GameServer.accept_game(pid, :player_1)

      %{game_server: pid}
    end

    test "if the game doesn't exist, its a `not_found`", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/games/#{Ecto.UUID.generate()}")
      assert html =~ "Not Found"
    end

    test "it can display a game in progress", %{conn: conn} = context do
      {:ok, _view, html} = live(conn, "/games/#{@game_id}")
      assert html =~ "TURN: 0 / 100"
    end
  end
end
