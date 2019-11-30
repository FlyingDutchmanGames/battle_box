defmodule BattleBox.Games.RobotGame.TerrainTest do
  use ExUnit.Case
  alias BattleBox.Games.RobotGame.Terrain

  @test_terrain %{
    {0, 0} => :normal,
    {1, 1} => :normal,
    {2, 2} => :spawn,
    {3, 3} => :spawn,
    {4, 4} => :obstacle,
    {5, 5} => :obstacle,
    {6, 6} => :invalid,
    {7, 7} => :invalid,
  }

  describe "default" do
    test "it has the correct number of spaces" do
      terrain = Terrain.default()
      assert length(Enum.into(terrain, [])) == 361
    end

    test "all the spaces are represented" do
      terrain = Terrain.default()

      expected_positions = for row <- 0..18, col <- 0..18, do: {row, col}
      actual_positions = Map.keys(terrain)

      assert Enum.sort(expected_positions) == Enum.sort(actual_positions)
    end
  end

  describe "getting spaces" do
    test "you can get spaces by type" do
      assert Terrain.normal(@test_terrain) == [{0,0}, {1,1}]
      assert Terrain.spawn(@test_terrain) == [{2,2}, {3,3}]
      assert Terrain.obstacle(@test_terrain) == [{4,4}, {5,5}]
      assert Terrain.invalid(@test_terrain) == [{6,6}, {7,7}]
    end
  end
end
