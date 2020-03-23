defmodule BattleBoxWeb.GamesLiveLiveTest do
  use BattleBoxWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias BattleBox.{Lobby, Game, GameEngine, GameEngine.GameServer, Games.RobotGame}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  @game_id Ecto.UUID.generate()

  test "it renders", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/live_games")
    assert html =~ "Live Games"
  end

  describe "While Games are going" do
    setup %{test: name} do
      :ok = GameEngineProvider.set_game_engine(name)
      on_exit(fn -> GameEngineProvider.reset!() end)

      {:ok, _} = GameEngine.start_link(name: name)
      {:ok, GameEngine.names(name)}
    end

    setup %{game_engine: game_engine} do
      {:ok, lobby} =
        Lobby.create(%{name: "TEST LOBBY", game_type: RobotGame, user_id: Ecto.UUID.generate()})

      {:ok, pid} =
        GameEngine.start_game(game_engine, %{
          players: %{
            1 => named_proxy(:player_1),
            2 => named_proxy(:player_2)
          },
          game: Game.new(id: @game_id, lobby: lobby, robot_game: RobotGame.new())
        })

      :ok = GameServer.accept_game(pid, 1)
      :ok = GameServer.accept_game(pid, 2)

      %{game_server: pid}
    end

    test "it renders with the game", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/live_games")
      assert html =~ @game_id
    end
  end
end
