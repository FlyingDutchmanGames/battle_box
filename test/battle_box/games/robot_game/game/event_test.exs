defmodule BattleBox.Games.RobotGame.Game.EventTest do
  alias BattleBox.Games.RobotGame.Game.Turn
  use BattleBox.DataCase
  import Ecto.Query, only: [from: 2]

  @robot_id "7b875c94-8fe0-4fa3-992a-d6d9f7da1a08"

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
      # Robot creation
      %{cause: :spawn, effects: [{:create_robot, :player_1, @robot_id, 50, {0, 0}}]},
      # Multiple Effects
      %{cause: @attack_move, effects: [{:damage, @robot_id, 42}, {:remove_robot, @robot_id}]}
    ]
    |> Enum.each(fn event ->
      game_id = Ecto.UUID.generate()
      turn = %Turn{game_id: game_id, events: [event], turn_number: 0}
      Repo.insert!(turn)

      retrieved_turn =
        Repo.one!(from t in Turn, where: t.game_id == ^game_id and t.turn_number == 0, select: t)

      expected = [event]

      assert ^expected =
               Enum.map(retrieved_turn.events, fn event -> Map.take(event, [:cause, :effects]) end)
    end)
  end
end
