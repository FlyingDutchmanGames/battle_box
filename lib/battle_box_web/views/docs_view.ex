defmodule BattleBoxWeb.DocsView do
  use BattleBoxWeb, :view
  import BattleBox.InstalledGames, only: [installed_games: 0]
  import BattleBox.Utilities.Humanize, only: [kebabify: 1]
end
