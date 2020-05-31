defmodule BattleBoxWeb.Live.FollowBackTest do
  use BattleBoxWeb.ConnCase, async: false
  alias BattleBoxWeb.Live.FollowBack
  import Phoenix.LiveViewTest

  @bot "bot-name"
  @lobby "lobby-name"
  @user %{"user" => "user-name"}

  @with_bot Map.merge(@user, %{"bot" => @bot})
  @with_lobby Map.merge(@user, %{"lobby" => @lobby})

  [
    {@user, "Disable Auto Following User (user-name)"},
    {@with_bot, "Disable Auto Following Bot (bot-name)"},
    {@with_lobby, "Disable Auto Following Lobby (lobby-name)"}
  ]
  |> Enum.each(fn {follow, expected} ->
    test "it displays the correct message when given a pid: #{inspect(expected)}", context do
      session = %{"follow" => unquote(Macro.escape(follow)), "game_pid" => self()}
      {:ok, _view, html} = live_isolated(context.conn, FollowBack, session: session)
      assert html =~ unquote(expected)
    end
  end)

  test "Pressing the button flips the auto follow on and off", %{conn: conn} do
    session = %{"follow" => @user, "game_pid" => self()}

    {:ok, view, html} = live_isolated(conn, FollowBack, session: session)
    assert html =~ "Disable Auto Following User (user-name)"

    html = view |> element("button") |> render_click()
    assert html =~ "Enable Auto Following User (user-name)"

    html = view |> element("button") |> render_click()
    assert html =~ "Disable Auto Following User (user-name)"
  end

  test "if the game pid dies while in auto follow mode, it trigger a redirect", %{conn: conn} do
    pid = spawn(fn -> Process.sleep(:infinity) end)
    session = %{"follow" => @user, "game_pid" => pid}
    {:ok, view, _html} = live_isolated(conn, FollowBack, session: session)
    Process.exit(pid, :kill)
    Process.sleep(10)
    assert_redirected(view, "/users/user-name/follow")
  end

  test "if the game pid dies & not auto follow mode, it goes passive and no redirect", %{conn: conn} do
    pid = spawn(fn -> Process.sleep(:infinity) end)
    session = %{"follow" => @user, "game_pid" => pid}
    {:ok, view, html} = live_isolated(conn, FollowBack, session: session)
    view |> element("button") |> render_click()
    Process.exit(pid, :kill)
    Process.sleep(10)
    assert render(view) == "Follow User (user-name)"
  end
end
