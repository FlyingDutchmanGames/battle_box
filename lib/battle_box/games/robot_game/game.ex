defmodule BattleBox.Games.RobotGame.Game do
  alias BattleBox.Games.RobotGame.GameMap
  alias BattleBox.Games.RobotGame.Settings
  defstruct terrain: GameMap.default(), robots: [], turn: 0, settings: %Settings{}, event_log: []
end
