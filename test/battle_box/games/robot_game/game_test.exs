defmodule BattleBox.Games.RobotGame.GameTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.{Game, GameMap, Settings}

  test "it has the correct defaults" do
    correct_defaults = %Game{
      settings: %Settings{},
      robots: [],
      turn: 0,
      terrain: GameMap.default()
    }

    assert correct_defaults == %Game{}
  end
end
