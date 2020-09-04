defmodule BattleBox.InstalledGames do
  import BattleBox.Utilities.Humanize, only: [kebabify: 1]

  @games Application.get_env(:battle_box, BattleBox.GameEngine)[:games] ||
           raise("Must set the :battle_box, BattleBox.GameEngine, :games config value")

  def installed_games, do: @games

  for game <- @games,
      id <- Enum.uniq([game, game.name, to_string(game.name), kebabify(game.title)]) do
    def game_type_name_to_module(unquote(id)), do: unquote(game)
  end
end
