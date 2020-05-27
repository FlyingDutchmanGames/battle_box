defmodule BattleBox.Games.RobotGame.Settings.TerrainTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.Settings.Terrain
  import BattleBox.Games.RobotGame.Settings.Terrain.Helpers

  @test_terrain ~t/0 0 1 1 2 2 3 3/

  describe "default" do
    test "it has the correct number of spaces" do
      terrain = Terrain.default()
      <<rows::8, cols::8, data::binary>> = terrain
      assert rows * cols == byte_size(data)
    end
  end

  describe "validate/1" do
    test "the default is valid" do
      assert :ok == Terrain.validate(Terrain.default())
    end

    test "it handles valid terrain" do
      [
        <<1, 1, 1>>,
        <<2, 2, 1, 2, 3, 1>>,
        <<40, 40>> <> :binary.copy(<<1>>, 40 * 40)
      ]
      |> Enum.each(fn terrain ->
        assert :ok = Terrain.validate(terrain)
      end)
    end

    test "it correctly identifies errors" do
      [
        {<<>>, "Illegal Size Header"},
        {<<1>>, "Illegal Size Header"},
        {<<1, 1>>, "Terrain data byte size must equal rows * cols"},
        {<<1, 256>>, "Rows and cols must be between 1 and 40"},
        {<<256, 1>>, "Rows and cols must be between 1 and 40"},
        {<<2, 2, 4, 5, 6, 7>>,
         "Terrain data must have bytes less than 3, but found bytes [4, 5, 6, 7]"}
      ]
      |> Enum.each(fn {terrain, error_msg} ->
        assert {:error, ^error_msg} = Terrain.validate(terrain)
      end)
    end
  end

  describe "getting spaces" do
    test "you can get spaces by type" do
      assert Terrain.normal(@test_terrain) == [[0, 2], [0, 3]]
      assert Terrain.spawn(@test_terrain) == [[0, 4], [0, 5]]
      assert Terrain.obstacle(@test_terrain) == [[0, 6], [0, 7]]
    end
  end

  describe "dimensions" do
    test "the dimensions of a one square map are 0s" do
      assert %{
               row_min: 0,
               row_max: 0,
               col_min: 0,
               col_max: 0
             } == Terrain.dimensions(~t/1/)
    end

    test "you can get the dimensions of one-d map" do
      assert %{
               row_min: 0,
               row_max: 0,
               col_min: 0,
               col_max: 10
             } == Terrain.dimensions(~t/11111111111/)
    end

    test "you can get the dimensions of a full terrain" do
      assert %{
               row_min: 0,
               row_max: 18,
               col_min: 0,
               col_max: 18
             } == Terrain.dimensions(Terrain.default())
    end
  end
end
