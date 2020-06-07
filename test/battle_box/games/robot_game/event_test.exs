defmodule BattleBox.Games.RobotGame.EventTest do
  alias BattleBox.Games.{RobotGame, RobotGame.Settings}
  use BattleBox.DataCase
  import BattleBox.Games.RobotGame.EventHelpers
  import Ecto.Query, only: [from: 2]

  @robot_id 1

  @move_move %{"type" => "move", "robot_id" => @robot_id, "target" => [0, 0]}
  @guard_move %{"type" => "guard", "robot_id" => @robot_id}
  @suicide_move %{"type" => "suicide", "robot_id" => @robot_id}
  @noop_move %{"type" => "noop", "robot_id" => @robot_id}
  @attack_move %{"type" => "attack", "robot_id" => @robot_id, "target" => [0, 0]}

  test "You get out what you get in" do
    [
      # Bare Basics
      %{turn: 1, seq_num: 1, cause: "spawn", effects: []},
      %{
        turn: 1,
        seq_num: 1,
        cause: %{"type" => "move", "target" => [0, 0], "robot_id" => @robot_id},
        effects: []
      },
      %{
        turn: 1,
        seq_num: 1,
        cause: %{"type" => "attack", "target" => [0, 0], "robot_id" => @robot_id},
        effects: []
      },
      %{turn: 1, seq_num: 1, cause: %{"type" => "guard", "robot_id" => @robot_id}, effects: []},
      # A little more realistic
      %{turn: 1, seq_num: 1, cause: @move_move, effects: [move_effect(@robot_id, 0, 0)]},
      %{turn: 1, seq_num: 1, cause: @guard_move, effects: [guard_effect(@robot_id)]},
      %{turn: 1, seq_num: 1, cause: @suicide_move, effects: [remove_robot_effect(@robot_id)]},
      %{turn: 1, seq_num: 1, cause: @noop_move, effects: []},
      %{turn: 1, seq_num: 1, cause: @attack_move, effects: [damage_effect(@robot_id, 20)]},
      # Robot creation
      %{
        turn: 1,
        seq_num: 1,
        cause: "spawn",
        effects: [create_robot_effect(@robot_id, 1, 50, 0, 0)]
      },
      # Multiple Effects
      %{
        turn: 1,
        seq_num: 1,
        cause: @attack_move,
        effects: [damage_effect(@robot_id, 42), remove_robot_effect(@robot_id)]
      },
      # Death
      %{
        turn: 1,
        seq_num: 1,
        cause: "death",
        effects: [remove_robot_effect(@robot_id)]
      }
    ]
    |> Enum.each(fn event ->
      game = RobotGame.new(settings: %Settings{}, events: [event]) |> RobotGame.changeset()

      {:ok, game} = Repo.insert(game)

      retrieved_game = Repo.one!(from g in RobotGame, where: g.id == ^game.id, select: g)

      assert [^event] =
               Enum.map(retrieved_game.events, fn event ->
                 event = update_in(event.effects, &Enum.sort/1)
                 Map.take(event, [:cause, :effects, :seq_num, :turn])
               end)
    end)
  end
end
