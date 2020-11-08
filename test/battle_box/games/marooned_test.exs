defmodule BattleBox.Games.MaroonedTest do
  use ExUnit.Case, async: true

  alias BattleBox.Game.Gameable
  alias BattleBox.Games.Marooned

  describe "impl Gameable" do
    test "It generates a command request" do
      assert %{
               1 => %{
                 turn: 0,
                 removed_locations: [],
                 available_to_move_to: _,
                 available_to_be_removed: _
               }
             } = Gameable.commands_requests(%Marooned{})
    end
  end
end
