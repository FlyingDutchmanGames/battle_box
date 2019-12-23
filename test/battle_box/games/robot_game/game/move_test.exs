defmodule BattleBox.Games.RobotGame.Game.MoveTest do
  import BattleBox.Games.RobotGame.Game.Move
  use ExUnit.Case, async: true

  @robot_id "7b875c94-8fe0-4fa3-992a-d6d9f7da1a08"
  @player_id "800bf58b-e8d0-4e58-9ba8-956fdd7fa065"

  @move_move %{type: :move, robot_id: @robot_id, target: {0, 0}}
  @guard_move %{type: :guard, robot_id: @robot_id}
  @suicide_move %{type: :suicide, robot_id: @robot_id}
  @noop_move %{type: :noop, robot_id: @robot_id}
  @attack_move %{type: :attack, robot_id: @robot_id, target: {0, 0}}

  test "You get out what you get in" do
    [
      # Bare Basics
      %{cause: :spawn, effects: []},
      %{cause: %{type: :move, target: {0, 0}, robot_id: @robot_id}, effects: []},
      %{cause: %{type: :attack, target: {0, 0}, robot_id: @robot_id}, effects: []},
      %{cause: %{type: :guard, robot_id: @robot_id}, effects: []},
      # A little more realistic
      %{cause: @move_move, effects: [{:move, @robot_id, {0, 0}}]},
      %{cause: @guard_move, effects: [{:guard, @robot_id}]},
      %{cause: @suicide_move, effects: [{:remove_robot, @robot_id}]},
      %{cause: @noop_move, effects: []},
      %{cause: @attack_move, effects: [{:damage, @robot_id, 42}]},
      # Robot creation (especially with weird opts)
      %{cause: :spawn, effects: [{:create_robot, @player_id, {0, 0}}]},
      %{cause: :spawn, effects: [{:create_robot, @player_id, {0, 0}, %{id: "TEST"}}]},
      %{cause: :spawn, effects: [{:create_robot, @player_id, {0, 0}, %{id: "TEST", hp: 50}}]},
      # Multiple Effects
      %{cause: @attack_move, effects: [{:damage, @robot_id, 42}, {:remove_robot, @robot_id}]}
    ]
    |> Enum.each(fn test_case ->
      assert {:ok, casted} = cast(test_case)
      assert {:ok, dumped} = dump(casted)
      assert {:ok, loaded} = load(dumped)

      assert test_case == loaded
    end)
  end
end
