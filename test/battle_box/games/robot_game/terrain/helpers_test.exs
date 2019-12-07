defmodule BattleBox.Games.RobotGame.Terrain.HelpersTest do
  use ExUnit.Case, async: true
  import BattleBox.Games.RobotGame.Terrain.Helpers

  describe "~t" do
    test "an empty sigil is an empty map" do
      assert %{} == ~t//
    end

    test "you can create a one position map" do
      assert %{{0, 0} => :normal} == ~t/1/
    end

    test "you can create a one dimensional terrain" do
      assert %{
               {0, 0} => :normal,
               {0, 1} => :normal,
               {0, 2} => :normal,
               {0, 3} => :normal
             } == ~t/1111/
    end

    test "you can create all the types of terrain" do
      assert %{
               {0, 0} => :inaccessible,
               {0, 1} => :normal,
               {0, 2} => :spawn,
               {0, 3} => :obstacle
             } == ~t/0123/
    end

    test "you can create a 2 dimensional terrain" do
      assert %{
               {0, 0} => :inaccessible,
               {0, 1} => :normal,
               {1, 0} => :spawn,
               {1, 1} => :obstacle
             } == ~t/01
                     23/
    end

    test "you can use spaces and they won't affect the map" do
      assert %{
               {0, 0} => :inaccessible,
               {0, 1} => :normal,
               {1, 0} => :spawn,
               {1, 1} => :obstacle
             } == ~t/
        0  1
        2  3
      /
    end

    test "you can space out the lines on the two dimensional ones and it stil works" do
      assert %{
               {0, 0} => :inaccessible,
               {0, 1} => :normal,
               {1, 0} => :spawn,
               {1, 1} => :obstacle
             } == ~t/
        01
        23
      /
    end

    test "you can make oddly shaped terrain" do
      assert %{
               {0, 0} => :inaccessible,
               {0, 1} => :normal,
               {1, 0} => :spawn
             } == ~t/
        01
        2
      /
    end
  end
end
