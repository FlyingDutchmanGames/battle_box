defmodule BattleBoxWeb.LobbyView do
  use BattleBoxWeb, :view
  import BattleBox.InstalledGames
  alias BattleBoxWeb.Live.Scores
  alias BattleBoxWeb.PageView

  def game_bots_to_game_name(game_bots) do
    game_bots
    |> Enum.map(fn game_bot -> game_bot.bot.name end)
    |> Enum.join(" vs. ")
  end
end
