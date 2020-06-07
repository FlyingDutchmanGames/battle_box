defmodule BattleBox.Games.RobotGame.Terrain.HelpersTest do
  use ExUnit.Case, async: true
  import BattleBox.Games.RobotGame.Settings.Terrain.Helpers

  describe "~t" do
    test "an empty sigil is an empty map" do
      assert <<0, 0>> == ~t//
    end

    test "you can create a one position map" do
      assert <<1, 1, 1>> == ~t/1/
    end

    test "you can create a one dimensional terrain" do
      assert <<1, 4, 1, 1, 1, 1>> == ~t/1111/
    end

    test "you can create all the types of terrain" do
      assert <<1, 4, 0, 1, 2, 3>> == ~t/0123/
    end

    test "you can create a 2 dimensional terrain" do
      assert <<2, 2, 0, 1, 2, 3>> == ~t/01
                                         23/
    end

    test "you can use spaces and they won't affect the map" do
      assert <<2, 2, 0, 1, 2, 3>> == ~t/ 0  1
        2  3/
    end

    test "you can space out the lines on the two dimensional ones and it stil works" do
      assert <<2, 2, 0, 1, 2, 3>> == ~t/ 01
        23/
    end
  end
end
