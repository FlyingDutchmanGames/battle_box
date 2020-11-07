defmodule BattleBoxWeb.HumanController do
  use BattleBoxWeb, :controller
  import BattleBox.Games.AiOpponent, only: [opponent_modules: 1, opponent_modules: 2]
  import BattleBox.InstalledGames, only: [installed_games: 0, game_type_name_to_module: 1]
  alias BattleBox.{Arena, Bot, GameEngine, Repo, User}
  import Ecto.Query

  def start_game(conn, %{
        "arena" => arena,
        "game_type" => game_type,
        "opponent" => opponent,
        "opponent_type" => "server_ai"
      }) do
    %Arena{} = arena = Repo.get_by(Arena, name: arena)
    game = game_type_name_to_module(game_type)
    {:ok, opponents} = opponent_modules(game, opponent)

    {:ok, human_bot} =
      if user = conn.assigns[:user],
        do: Bot.human_bot(user),
        else: Bot.anon_human_bot()

    {:ok, %{game_id: game_id, human_server_id: human_server_id}} =
      GameEngine.human_vs_ai(game_engine(), arena, human_bot, opponents)

    text(conn, "hello")
  end

  def play(conn, %{"game_type" => game_type, "arena" => arena}) do
    %Arena{} = arena = Repo.get_by(Arena, name: arena)

    nav_segments = [
      "play",
      {"game_type", Routes.human_path(conn, :play)},
      game_type,
      {"arena", Routes.human_path(conn, :play, game_type)},
      arena.name
    ]

    game = game_type_name_to_module(game_type)
    {:ok, opponents} = opponent_modules(game)

    render(conn, "opponent_select.html",
      arena: arena,
      game: game,
      opponents: opponents,
      segments: nav_segments
    )
  end

  def play(conn, %{"game_type" => game_type}) do
    nav_segments = [
      "play",
      {"game_type", Routes.human_path(conn, :play)},
      game_type
    ]

    game = game_type_name_to_module(game_type)

    arenas =
      if user = conn.assigns[:current_user],
        do: user_arenas(user, game),
        else: []

    render(conn, "arena_select.html",
      segments: nav_segments,
      arenas: arenas,
      game: game
    )
  end

  def play(conn, _params) do
    nav_options =
      for game <- installed_games(),
          do: {to_string(game.name), Routes.human_path(conn, :play, game.name)}

    render(conn, "game_type_select.html",
      nav_segments: ["play"],
      nav_options: nav_options,
      games: installed_games()
    )
  end

  defp user_arenas(%User{id: id}, game_type) do
    Arena
    |> where(user_id: ^id)
    |> where(game_type: ^game_type)
    |> Repo.all()
  end
end
