defmodule BattleBoxWeb.FollowControllerTest do
  use BattleBoxWeb.ConnCase, async: false

  setup do
    {:ok, user} = create_user()
    %{user: user}
  end

  test "an invalid user is a 404", %{conn: conn} do
    conn = conn |> get("/users/fake-user/follow")
    assert html_response(conn, 404) =~ "User (fake-user) Not Found"
  end

  test "You can do it for a real user", %{conn: conn, user: user} do
    conn = conn |> get("/users/#{user.username}/follow")
    html = html_response(conn, 200)

    {:ok, document} = Floki.parse_document(html)
    assert [break_crumbs] = Floki.find(document, ".subhead-heading")

    assert Regex.replace(~r/\s+/, Floki.text(break_crumbs), " ") ==
             "/ Users / #{user.username} / Follow / "
  end

  test "you can do it with a arena", %{conn: conn, user: user} do
    {:ok, arena} = robot_game_arena(%{user: user, arena_name: "test-name"})

    conn = conn |> get("/users/#{user.username}/arenas/#{arena.name}/follow")
    html = html_response(conn, 200)

    {:ok, document} = Floki.parse_document(html)
    assert [break_crumbs] = Floki.find(document, ".subhead-heading")

    assert Regex.replace(~r/\s+/, Floki.text(break_crumbs), " ") ==
             "/ Users / #{user.username} / Arenas / test-name / Follow / "
  end

  test "you can do it with a bot", %{conn: conn, user: user} do
    {:ok, bot} = create_bot(user: user, bot_name: "test-name")

    conn = conn |> get("/users/#{user.username}/bots/#{bot.name}/follow")
    html = html_response(conn, 200)

    {:ok, document} = Floki.parse_document(html)
    assert [break_crumbs] = Floki.find(document, ".subhead-heading")

    assert Regex.replace(~r/\s+/, Floki.text(break_crumbs), " ") ==
             "/ Users / #{user.username} / Bots / test-name / Follow / "
  end
end
