defmodule BattleBox.BattleBoxGameTest do
  use BattleBox.DataCase
  alias BattleBox.{BattleBoxGame, Repo}

  @lobby_id Ecto.UUID.generate()

  test "you can persist them" do
    assert {:ok, _bbg} =
             Repo.insert(%BattleBoxGame{
               lobby_id: @lobby_id,
               battle_box_game_bots: []
             })
  end

  test "new/1 creates one" do
    assert %BattleBoxGame{battle_box_game_bots: [], lobby_id: nil} = BattleBoxGame.new()

    assert %BattleBoxGame{battle_box_game_bots: [], lobby_id: @lobby_id} =
             BattleBoxGame.new(lobby_id: @lobby_id)
  end
end
