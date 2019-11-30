defmodule BattleBox.Games.RobotGame.GameTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.{Game, Terrain}

  test "it has the correct default settings" do
    assert %{
             spawn_every: 10,
             spawn_per_player: 5,
             robot_hp: 50,
             attack_range: %{min: 8, max: 10},
             collision_damage: 5,
             suicide_damage: 15,
             max_turns: 100
           } == Game.Settings.new()
  end

  test "it has the correct defaults" do
    correct_defaults = %{
      settings: Game.Settings.new(),
      robots: [],
      turn: 0,
      terrain: Terrain.default(),
      players: ["player_1", "player_2"]
    }

    assert correct_defaults == Game.new()
  end
end
