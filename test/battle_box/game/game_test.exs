defmodule BattleBox.GameTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Game, Repo}

  @lobby_id Ecto.UUID.generate()

  test "you can persist them" do
    assert {:ok, _game} =
             %Game{game_type: BattleBox.Games.RobotGame, lobby_id: @lobby_id, game_bots: []}
             |> Repo.insert()
  end
end
