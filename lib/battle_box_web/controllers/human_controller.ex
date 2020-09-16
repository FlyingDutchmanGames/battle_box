defmodule BattleBoxWeb.HumanController do
  use BattleBoxWeb, :controller
  import BattleBox.Games.AiOpponent, only: [opponent_modules: 1]
  import BattleBox.InstalledGames, only: [installed_games: 0, game_type_name_to_module: 1]

  def start_game(conn, %{"game_type" => _game_type, "opponent" => _opponent}) do
  end

  def play(conn, %{"game_type" => game_type}) do
    nav_segments = [{"play", Routes.human_path(conn, :play)}, game_type]
    game = game_type_name_to_module(game_type)
    {:ok, opponents} = opponent_modules(game)

    render(conn, "opponent_select.html",
      segments: nav_segments,
      opponents: opponents,
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
end
