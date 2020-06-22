defmodule BattleBox.InstalledGames do
  import BattleBox.Utilities.Humanize, only: [kebabify: 1]

  @games Application.get_env(:battle_box, BattleBox.GameEngine)[:games] ||
           raise("Must set the :battle_box, BattleBox.GameEngine, :games config value")

  def installed_games, do: @games

  for game <- @games do
    def game_type_name_to_module(unquote(game)), do: unquote(game)
    def game_type_name_to_module(unquote(game.name)), do: unquote(game)
    def game_type_name_to_module(unquote("#{game.name}")), do: unquote(game)
    def game_type_name_to_module(unquote(kebabify(game.title))), do: unquote(game)
  end
end
