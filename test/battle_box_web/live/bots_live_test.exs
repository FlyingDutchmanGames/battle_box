defmodule BattleBoxWeb.BotsLiveTest do
  use BattleBoxWeb.ConnCase
  import Phoenix.LiveViewTest
  alias BattleBox.{Bot, GameEngine, GameEngineProvider.Mock}

  @user_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _pid} = GameEngine.start_link(name: name)
    Mock.set_game_engine(name)
    on_exit(fn -> Mock.reset!() end)
  end

  setup do
    {:ok, user} = create_user(%{user_id: @user_id})

    {:ok, bot} =
      Bot.create(%{
        user_id: @user_id,
        name: "TEST BOT"
      })

    %{bot: bot, user: user}
  end

  test "with a non existant user, it returns not found", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/users/#{Ecto.UUID.generate()}/bots")
    assert html =~ "Not Found"
  end

  test "it will render a players bots", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/users/#{@user_id}/bots")
    assert html =~ "TEST BOT"
  end
end
