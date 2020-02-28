defmodule BattleBox.GameBotTest do
  use BattleBox.DataCase
  alias BattleBox.{GameBot, Repo}

  @bot_id Ecto.UUID.generate()
  @bbg_id Ecto.UUID.generate()

  test "you can persist them" do
    changeset =
      GameBot.changeset(%GameBot{}, %{
        player: "foo",
        score: 0,
        bot_id: @bot_id,
        game_id: @bbg_id
      })

    assert {:ok, _bot} = Repo.insert(changeset)
  end

  test "new/1 creates one" do
    assert %GameBot{score: 10, player: "BAR", bot_id: @bot_id} =
             GameBot.new(score: 10, player: "BAR", bot_id: @bot_id)
  end
end
