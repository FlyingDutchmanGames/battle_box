defmodule BattleBoxWeb.HumanControllerTest do
  use BattleBoxWeb.ConnCase, async: false
  alias BattleBox.{InstalledGames, GameEngine, Games.Marooned}

  setup %{test: name} do
    {:ok, _pid} = GameEngine.start_link(name: name)
    GameEngine.Provider.set_game_engine(name)
    on_exit(fn -> GameEngine.Provider.reset!() end)
    GameEngine.names(name)
  end

  setup %{conn: conn} do
    {:ok, user} = create_user()
    {:ok, arena} = marooned_arena(user: user)
    conn = signin(conn, user: user)
    %{arena: arena, conn: conn}
  end

  describe "GET /play/(...etc)" do
    test "it will let you select a game", %{conn: conn} do
      html =
        conn
        |> get("/play")
        |> html_response(200)

      for game <- InstalledGames.installed_games() do
        assert html =~ game.title()
      end
    end

    test "if you give it a game type, it will let you select an arena", %{
      conn: conn,
      arena: arena
    } do
      html =
        conn
        |> get("/play/game_type/marooned")
        |> html_response(200)

      assert html =~ "Marooned"

      for %{name: name} <- Marooned.default_arenas() do
        assert html =~ name
      end

      assert html =~ arena.name
    end

    test "if you select an arena, it will show opponents", %{conn: conn, arena: arena} do
      html =
        conn
        |> get("/play/game_type/marooned/arena/#{arena.name}")
        |> html_response(200)

      for opponent <- Marooned.ais() do
        assert html =~ opponent.name()
      end
    end
  end

  describe "POST /play" do
    test "You can start a game", %{conn: conn, arena: arena, game_engine: game_engine} do
      conn =
        post(conn, "/play", %{
          "arena" => arena.name,
          "game_type" => "marooned",
          "opponent" => "wilson",
          "opponent_type" => "server_ai"
        })

      "/human/" <> id = redirected_to(conn, 302)

      Process.sleep(30)
      %{game_id: game_id, pid: pid} = GameEngine.get_human_server(game_engine, id)
      assert Process.alive?(pid)
      %{pid: pid} = GameEngine.get_game_server(game_engine, game_id)
      assert Process.alive?(pid)
    end
  end
end
