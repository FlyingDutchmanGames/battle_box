defmodule BattleBox.InstalledGames do
  @games Application.get_env(:battle_box, BattleBox.GameEngine)[:games] ||
           raise("Must set the :battle_box, BattleBox.GameEngine, :games config value")

  def installed_games, do: @games
end
