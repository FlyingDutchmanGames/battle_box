defmodule BattleBox.Games.RobotGame.Settings.TerrainTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.RobotGame.Settings.Terrain
  import BattleBox.Games.RobotGame.Settings.Terrain.Helpers

  describe "spawns" do
    test "it gives back the spawns" do
      assert [] == Terrain.spawns(<<0, 0>>)
      assert [[0, 0]] == Terrain.spawns(<<1, 1, 2>>)
      assert [[0, 0], [0, 1]] == Terrain.spawns(<<2, 2, 2, 0, 2, 0>>)
      assert [[0, 0], [2, 0]] == Terrain.spawns(<<1, 4, 2, 0, 2, 0>>)
    end
  end

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
        <<2, 2, 1, 2, 0, 1>>,
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
         "Terrain data must have bytes less than 2, but found bytes [4, 5, 6, 7]"}
      ]
      |> Enum.each(fn {terrain, error_msg} ->
        assert {:error, ^error_msg} = Terrain.validate(terrain)
      end)
    end
  end

  describe "at_location/set_at_location" do
    test "you can get the terrain at a location" do
      assert :normal == Terrain.at_location(<<2, 2, 0, 0, 1, 0>>, [0, 1])
      assert :normal == Terrain.at_location(<<1, 4, 0, 0, 1, 0>>, [2, 0])
    end

    test "you can set the terrain at a location" do
      before = <<2, 2, 0, 0, 0, 0>>
      expect = <<2, 2, 0, 0, 1, 0>>
      assert expect == Terrain.set_at_location(before, [0, 1], :normal)

      before = <<1, 4, 0, 0, 0, 0>>
      expect = <<1, 4, 0, 0, 1, 0>>
      assert expect == Terrain.set_at_location(before, [2, 0], :normal)

      before = <<1, 4, 0, 0, 1, 0>>
      expect = <<1, 4, 1, 0, 1, 0>>
      assert expect == Terrain.set_at_location(before, [0, 0], :normal)
    end
  end

  describe "location_accessible?/2" do
    test "it gives accessible for everything besides :inaccessible" do
      terrain = <<1, 3, 0, 1, 2>>
      refute Terrain.location_accessible?(terrain, [-1, -1])
      refute Terrain.location_accessible?(terrain, [0, 0])
      assert Terrain.location_accessible?(terrain, [1, 0])
      assert Terrain.location_accessible?(terrain, [2, 0])
    end
  end

  describe "resize" do
    test "it get to the right size" do
      assert <<10::8, 10::8, _rest::binary>> = Terrain.resize(<<1, 1, 0>>, 10, 10)
      assert <<4::8, 5::8, _rest::binary>> = Terrain.resize(<<1, 1, 0>>, 4, 5)
      assert <<1::8, 1::8, _rest::binary>> = Terrain.resize(<<1, 1, 0>>, 1, 1)
      assert <<1::8, 1::8, _rest::binary>> = Terrain.resize(<<2, 2, 0, 0, 0, 0>>, 1, 1)
    end
  end

  describe "dimensions" do
    test "the dimensions of a one square map are 0s" do
      assert %{
               rows: 1,
               cols: 1
             } == Terrain.dimensions(~t/1/)
    end

    test "you can get the dimensions of one-d map" do
      assert %{
               rows: 1,
               cols: 10
             } == Terrain.dimensions(~t/1111111111/)
    end

    test "you can get the dimensions of a full terrain" do
      assert %{
               rows: 19,
               cols: 19
             } == Terrain.dimensions(Terrain.default())
    end
  end
end
