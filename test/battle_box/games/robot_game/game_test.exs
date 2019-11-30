defmodule BattleBox.Games.RobotGame.GameTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.{Game, GameMap, Settings}

  test "it has the correct defaults" do
    correct_defaults = %{
      settings: Settings.new(),
      robots: [],
      turn: 0,
      terrain: GameMap.default(),
      event_log: []
    }

    assert correct_defaults == Game.new()
  end
end
