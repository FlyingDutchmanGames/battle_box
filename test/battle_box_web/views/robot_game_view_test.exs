defmodule BattleBoxWeb.RobotGameViewTest do
  use BattleBoxWeb.ConnCase, async: true
  alias BattleBoxWeb.RobotGameView

  describe "terrain_number/1" do
    test "the terrain numbering of a starting column is displayed" do
      assert 10 == RobotGameView.terrain_number({0, 10})
    end

    test "the terrain numbering of a starting row is displayed" do
      assert 10 == RobotGameView.terrain_number({10, 0})
    end

    test "0 is displayed at the origin" do
      assert 0 == RobotGameView.terrain_number({0, 0})
    end
  end
end
