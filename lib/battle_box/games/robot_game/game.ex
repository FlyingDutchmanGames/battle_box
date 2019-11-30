defmodule BattleBox.Games.RobotGame.Game do
  alias BattleBox.Games.RobotGame.{Terrain, Settings}

  def new() do
    %{terrain: Terrain.default(), robots: [], turn: 0, settings: Settings.new(), event_log: []}
  end
end
