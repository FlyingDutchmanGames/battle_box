defmodule BattleBox.GameTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Game, Repo}

  @arena_id Ecto.UUID.generate()

  test "you can persist them" do
    assert {:ok, _game} =
             %Game{game_type: BattleBox.Games.RobotGame, arena_id: @arena_id, game_bots: []}
             |> Repo.insert()
  end

  describe "preload_game_data" do
    test "with nil, yields nil" do
      assert Game.preload_game_data(nil) == nil
    end
  end
end
