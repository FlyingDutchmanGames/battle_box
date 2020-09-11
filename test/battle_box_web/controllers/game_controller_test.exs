defmodule BattleBoxWeb.GameControllerTest do
  use BattleBoxWeb.ConnCase, async: false
  alias BattleBox.Game
  alias BattleBox.Games.Marooned

  @game1_id Ecto.UUID.generate()
  @game2_id Ecto.UUID.generate()
  @game3_id Ecto.UUID.generate()

  describe "It 404s at the right time in the right ways" do
    [
      {"/users/fake-user/games", "User (fake-user) Not Found"},
      {"/users/fake-user/bots/fake-bot/games", "Bot (fake-bot) for User (fake-user) Not Found"},
      {"/users/fake-user/arenas/fake-arena/games",
       "Arena (fake-arena) for User (fake-user) Not Found"}
    ]
    |> Enum.each(fn {path, expected} ->
      test "Fake path #{path} yields the correct error message", %{conn: conn} do
        conn = get(conn, unquote(path))
        assert html_response(conn, 404) =~ unquote(expected)
      end
    end)
  end

  describe "it filters the games correctly" do
    setup do
      {:ok, user1} = create_user()
      {:ok, user2} = create_user()
      {:ok, bot1} = create_bot(user: user1, bot_name: "bot1")
      {:ok, bot2} = create_bot(user: user2, bot_name: "bot2")
      {:ok, arena1} = marooned_arena(arena_name: "arena1")
      {:ok, arena2} = marooned_arena(arena_name: "arena2")

      arena1 = Repo.preload(arena1, :user)
      bot1 = Repo.preload(bot1, :user)

      %Game{
        id: @game1_id,
        arena: arena1,
        game_type: Marooned,
        game_bots: [
          %{bot: bot1, score: 1, winner: true, player: 1},
          %{bot: bot2, score: 1, winner: false, player: 2}
        ]
      }
      |> Repo.insert!()

      %Game{
        id: @game2_id,
        arena: arena1,
        game_type: Marooned,
        game_bots: [
          %{bot: bot1, score: 1, winner: true, player: 1}
        ]
      }
      |> Repo.insert!()

      %Game{
        id: @game3_id,
        arena: arena2,
        game_type: Marooned,
        game_bots: [
          %{bot: bot2, score: 2, winner: true, player: 1}
        ]
      }
      |> Repo.insert!()

      %{user1: user1, bot1: bot1, arena1: arena1}
    end

    test "asking for /games yields all the games", %{conn: conn} do
      conn = get(conn, "/games")
      html = html_response(conn, 200)
      assert html =~ @game1_id
      assert html =~ @game2_id
      assert html =~ @game3_id
    end

    test "asking for games in an arena only gives the games for that arena", %{
      conn: conn,
      arena1: arena
    } do
      conn = get(conn, "/users/#{arena.user.username}/arenas/#{arena.name}/games")
      html = html_response(conn, 200)
      assert html =~ @game1_id
      assert html =~ @game2_id
      refute html =~ @game3_id
    end

    test "asking for the games for a user only gives the games for that user", %{
      conn: conn,
      user1: user
    } do
      conn = get(conn, "/users/#{user.username}/games")
      html = html_response(conn, 200)
      assert html =~ @game1_id
      assert html =~ @game2_id
      refute html =~ @game3_id
    end

    test "asking for the games for a bot only gives you the games that bot was involved with", %{
      conn: conn,
      bot1: bot
    } do
      conn = get(conn, "/users/#{bot.user.username}/bots/#{bot.name}/games")
      html = html_response(conn, 200)
      assert html =~ @game1_id
      assert html =~ @game2_id
      refute html =~ @game3_id
    end

    test "it 404s with a non real user", %{conn: conn} do
      conn = get(conn, "/users/fake-user/games")
      assert html_response(conn, 404) =~ "User (fake-user) Not Found"
    end

    test "it 404s with a fake arena for a real user", %{conn: conn, user1: user} do
      conn = get(conn, "/users/#{user.username}/arenas/fake-arena/games")

      assert html_response(conn, 404) =~
               "Arena (fake-arena) for User (#{user.username}) Not Found"
    end

    test "it 404s with a fake bot for a real user", %{conn: conn, user1: user} do
      conn = get(conn, "/users/#{user.username}/bots/fake-bot/games")
      assert html_response(conn, 404) =~ "Bot (fake-bot) for User (#{user.username}) Not Found"
    end
  end
end
