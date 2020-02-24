defmodule BattleBox.BattleBoxGameBotTest do
  use BattleBox.DataCase
  alias BattleBox.{BattleBoxGameBot, Repo}

  @bot_id Ecto.UUID.generate()
  @bbg_id Ecto.UUID.generate()

  test "you can persist them" do
    changeset =
      BattleBoxGameBot.changeset(%BattleBoxGameBot{}, %{
        player: "foo",
        score: 0,
        bot_id: @bot_id,
        battle_box_game_id: @bbg_id
      })

    assert {:ok, _bot} = Repo.insert(changeset)
  end

  test "new/1 creates one" do
    assert %BattleBoxGameBot{score: 10, player: "BAR", bot_id: @bot_id} =
             BattleBoxGameBot.new(score: 10, player: "BAR", bot_id: @bot_id)
  end
end
