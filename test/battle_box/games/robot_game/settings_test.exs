defmodule BattleBox.Games.RobotGame.SettingsTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.Settings

  test "it has the correct default settings" do
    assert %Settings{
             spawn_every: 10,
             spawn_per_player: 5,
             robot_hp: 50,
             attack_range: %{min: 8, max: 10},
             collision_damage: 5,
             suicide_damage: 15,
             max_turns: 100
           } == %Settings{}
  end
end
