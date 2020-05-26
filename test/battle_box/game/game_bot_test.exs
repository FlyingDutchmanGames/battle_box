defmodule BattleBox.GameBotTest do
  use BattleBox.DataCase
  alias BattleBox.{GameBot, Repo}

  @bot_id Ecto.UUID.generate()
  @game_id Ecto.UUID.generate()

  test "you can persist them" do
    assert {:ok, _bot} =
             %GameBot{bot_id: @bot_id, game_id: @game_id}
             |> GameBot.changeset(%{player: 32, score: 0})
             |> Repo.insert()
  end
end
