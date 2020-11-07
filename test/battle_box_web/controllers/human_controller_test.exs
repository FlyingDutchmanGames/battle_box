defmodule BattleBoxWeb.HumanControllerTest do
  use BattleBoxWeb.ConnCase, async: false
  alias BattleBox.Games.Marooned
  alias BattleBox.InstalledGames

  setup %{conn: conn} do
    {:ok, user} = create_user()
    {:ok, arena} = marooned_arena(user: user)
    conn = signin(conn, user: user)
    %{arena: arena, conn: conn}
  end

  describe "GET /play" do
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
end
