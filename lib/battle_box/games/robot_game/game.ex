defmodule BattleBox.Games.RobotGame.Game do
  alias BattleBox.Games.RobotGame.{GameMap, Settings}

  def new() do
    %{terrain: GameMap.default(), robots: [], turn: 0, settings: Settings.new(), event_log: []}
  end
end
