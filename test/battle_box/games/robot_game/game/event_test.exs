defmodule BattleBox.Games.RobotGame.Game.EventTest do
  alias BattleBox.Games.RobotGame.Game
  use BattleBox.DataCase
  import Ecto.Query, only: [from: 2]

  @robot_id "7b875c94-8fe0-4fa3-992a-d6d9f7da1a08"
  @player_id "7b875c94-8fe0-4fa3-992a-d6d9f7da1a08"

  @move_move %{type: :move, robot_id: @robot_id, target: {0, 0}}
  @guard_move %{type: :guard, robot_id: @robot_id}
  @suicide_move %{type: :suicide, robot_id: @robot_id}
  @noop_move %{type: :noop, robot_id: @robot_id}
  @attack_move %{type: :attack, robot_id: @robot_id, target: {0, 0}}

  test "You get out what you get in" do
    [
      # Bare Basics
      %{turn_num: 1, seq_num: 1, cause: :spawn, effects: []},
      %{
        turn_num: 1,
        seq_num: 1,
        cause: %{type: :move, target: {0, 0}, robot_id: @robot_id},
        effects: []
      },
      %{
        turn_num: 1,
        seq_num: 1,
        cause: %{type: :attack, target: {0, 0}, robot_id: @robot_id},
        effects: []
      },
      %{turn_num: 1, seq_num: 1, cause: %{type: :guard, robot_id: @robot_id}, effects: []},
      # A little more realistic
      %{turn_num: 1, seq_num: 1, cause: @move_move, effects: [{:move, @robot_id, {0, 0}}]},
      %{turn_num: 1, seq_num: 1, cause: @guard_move, effects: [{:guard, @robot_id}]},
      %{turn_num: 1, seq_num: 1, cause: @suicide_move, effects: [{:remove_robot, @robot_id}]},
      %{turn_num: 1, seq_num: 1, cause: @noop_move, effects: []},
      %{turn_num: 1, seq_num: 1, cause: @attack_move, effects: [{:damage, @robot_id, 42}]},
      # Robot creation
      %{
        turn_num: 1,
        seq_num: 1,
        cause: :spawn,
        effects: [{:create_robot, :player_1, @robot_id, 50, {0, 0}}]
      },
      # Multiple Effects
      %{
        turn_num: 1,
        seq_num: 1,
        cause: @attack_move,
        effects: [{:damage, @robot_id, 42}, {:remove_robot, @robot_id}]
      }
    ]
    |> Enum.each(fn event ->
      game =
        Game.new(player_1: @player_id, player_2: @player_id, events: [event]) |> Game.changeset()

      {:ok, game} = Repo.insert(game)

      retrieved_game = Repo.one!(from g in Game, where: g.id == ^game.id, select: g)

      assert [^event] =
               Enum.map(retrieved_game.events, fn event ->
                 Map.take(event, [:cause, :effects, :seq_num, :turn_num])
               end)
    end)
  end
end
