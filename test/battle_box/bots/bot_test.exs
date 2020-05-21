defmodule BattleBox.BotTest do
  use BattleBox.DataCase
  alias BattleBox.Bot

  describe "validations" do
    test "Name must be greater than 1" do
      changeset = Bot.changeset(%Bot{}, %{name: ""})
      refute changeset.valid?
    end

    test "Name may not be longer than 20" do
      name = :crypto.strong_rand_bytes(11) |> Base.encode16()
      assert String.length(name) > 20
      changeset = Bot.changeset(%Bot{}, %{name: name})
      refute changeset.valid?
    end
  end
end
