defmodule BattleBoxWeb.HumanControllerTest do
  use BattleBoxWeb.ConnCase, async: false
  alias BattleBox.Games.Marooned

  describe "GET /play" do
    test "it will let you select a game", %{conn: conn} do
      html =
        conn
        |> get("/play")
        |> html_response(200)

      assert html =~ "Marooned"
    end

    test "if you give it a game type, it will let you select an opponent", %{conn: conn} do
      html =
        conn
        |> get("/play/marooned")
        |> html_response(200)

      assert html =~ "Marooned"

      for ai <- Marooned.ais() do
        assert html =~ ai
      end
    end
  end

  # describe "POST /play" do
  #   test "it will let you start a game, and redirect to it"
  # end
end
