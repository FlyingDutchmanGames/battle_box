defmodule BattleBoxWeb.ConnectionsLiveTest do
  use BattleBoxWeb.ConnCase
  import Phoenix.LiveViewTest
  alias BattleBox.{GameEngine, GameEngineProvider.Mock}

  @user_id Ecto.UUID.generate()

  setup %{conn: conn} do
    %{conn: signin(conn, user_id: @user_id)}
  end

  test "with a non existant user, it returns not found", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/users/#{Ecto.UUID.generate()}/connections")
    assert html =~ "Not Found"
  end

  test "with a gibberish (non uuidv4) user id its not found", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/users/abcdefg/connections")
    assert html =~ "Not Found"
  end

  describe "rendering connections" do
    setup %{test: name} do
      {:ok, _pid} = GameEngine.start_link(name: name)
      Mock.set_game_engine(name)
      on_exit(fn -> Mock.reset!() end)
    end

    test "it can render a player's connections", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/users/#{@user_id}/connections")
      {:ok, _document} = Floki.parse_document(html)
    end
  end
end
