defmodule BattleBoxWeb.LobbyLiveTest do
  use BattleBoxWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias BattleBox.{GameEngine, Lobby}

  @user_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup %{game_engine: game_engine} do
    :ok = GameEngineProvider.set_game_engine(game_engine)
    on_exit(fn -> :ok = GameEngineProvider.reset!() end)
  end

  setup do
    {:ok, user} = create_user(user_id: @user_id)

    {:ok, lobby} = Lobby.create(%{name: "TEST LOBBY", game_type: "robot_game", user_id: @user_id})

    %{lobby: lobby, user: user}
  end

  test "renders not found for a non existant lobby", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/lobbies/#{Ecto.UUID.generate()}")
    assert html =~ "Not Found"
  end

  test "it can show a lobby", %{conn: conn} = context do
    {:ok, _view, html} = live(conn, "/lobbies/#{context.lobby.id}")
    assert html =~ "#{context.user.github_login_name} / #{context.lobby.name}"
  end
end
