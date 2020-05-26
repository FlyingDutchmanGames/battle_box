defmodule BattleBox.GameBotTest do
  use BattleBox.DataCase
  alias BattleBox.{GameBot, Repo}

  @bot_id Ecto.UUID.generate()
  @game_id Ecto.UUID.generate()

  test "you can persist them" do
    changeset =
      GameBot.changeset(%GameBot{bot_id: @bot_id, game_id: @game_id}, %{
        player: 32,
        score: 0
      })

    assert {:ok, _bot} = Repo.insert(changeset)
  end
end
