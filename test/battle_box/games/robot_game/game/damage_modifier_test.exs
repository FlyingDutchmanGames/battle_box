defmodule BattleBox.Games.RobotGame.Game.DamageModifierTest do
  import BattleBox.Games.RobotGame.Game.DamageModifier
  use ExUnit.Case, async: true

  test "garbage in garbage out (jk you get out whatcha put in)" do
    [
      %{min: 1, max: 1},
      %{min: 0, max: 1000},
      0,
      1,
      2
    ]
    |> Enum.each(fn test_case ->
      assert {:ok, casted} = cast(test_case)
      assert {:ok, dumped} = dump(casted)
      assert {:ok, loaded} = load(dumped)

      assert test_case == loaded
    end)
  end

  test "invalid stuff doesn't cast" do
    [
      %{"min" => 1, "max" => 2},
      %{"always" => 2},
      :test
    ]
    |> Enum.each(fn test_case ->
      assert :error = cast(test_case)
    end)
  end
end
