defmodule BattleBox.BotTest do
  use BattleBox.DataCase
  alias BattleBox.{Bot, Repo}

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

  test "names are unique within (within a user)" do
    {:ok, user1} = create_user()
    {:ok, user2} = create_user()

    user_1_changeset =
      Ecto.build_assoc(user1, :bots)
      |> Bot.changeset(%{name: "foo"})

    user_2_changeset =
      Ecto.build_assoc(user2, :bots)
      |> Bot.changeset(%{name: "foo"})

    assert {:ok, _bot} = Repo.insert(user_1_changeset)
    assert {:ok, _bot} = Repo.insert(user_2_changeset)

    assert {:error, %{errors: errors}} = Repo.insert(user_1_changeset)

    assert errors == [
             name:
               {"Bot with that name already exists for your user",
                [constraint: :unique, constraint_name: "bots_user_id_name_index"]}
           ]
  end

  test "bot names are case insensitive" do
    {:ok, user} = create_user()

    {:ok, _bot} =
      Ecto.build_assoc(user, :bots)
      |> Bot.changeset(%{name: "FOO"})
      |> Repo.insert()

    assert %Bot{name: "FOO"} = Repo.get_by(Bot, name: "foo")
    assert %Bot{name: "FOO"} = Repo.get_by(Bot, name: "FOO")
    assert %Bot{name: "FOO"} = Repo.get_by(Bot, name: "fOo")
  end

  describe "get or create by name" do
    setup do
      {:ok, user} = create_user()
      %{user: user}
    end

    test "when no bot exists, it creates one", %{user: user} do
      assert {:ok, bot} = Bot.get_or_create_by_name(user, "foo")
    end

    test "when a bot exists, it returns it", %{user: user} do
      {:ok, existing_bot} =
        user
        |> Ecto.build_assoc(:bots)
        |> Bot.changeset(%{name: "foo"})
        |> Repo.insert()

      {:ok, bot} = Bot.get_or_create_by_name(user, "foo")

      assert bot.id == existing_bot.id
    end

    test "it enforces the naming rules", %{user: user} do
      assert {:error, %{errors: errors}} =
               Bot.get_or_create_by_name(
                 user,
                 "fooooooooooooooooooooooooooooooooooooooooooooooooooooo"
               )

      assert errors == [
               name:
                 {"should be at most %{count} character(s)",
                  [count: 20, validation: :length, kind: :max, type: :string]}
             ]
    end
  end
end
