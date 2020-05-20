defmodule BattleBox.BotTest do
  use BattleBox.DataCase
  alias BattleBox.{Bot, Repo}

  @user_id Ecto.UUID.generate()

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

  describe "getting a bot" do
    setup do
      {:ok, user} = create_user(id: @user_id)

      {:ok, bot} =
        user
        |> Ecto.build_assoc(:bots)
        |> Bot.changeset(%{name: "Test Name"})
        |> Repo.insert()

      %{user: user, bot: bot}
    end

    test "you can get by name", %{bot: %{id: id, name: name}} do
      assert nil == Bot.get_by_name("NOT A REAL NAME")
      assert %{id: ^id} = Bot.get_by_name(name)
    end
  end
end
