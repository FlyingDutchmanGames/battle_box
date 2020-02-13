defmodule BattleBox.BotTest do
  use BattleBox.DataCase
  alias BattleBox.{Bot, User, Repo}

  @user_id Ecto.UUID.generate()

  test "bots auto generate tokens" do
    assert {:ok, bot} =
             Bot.changeset(%Bot{}, %{
               name: "Test Name",
               user_id: @user_id
             })
             |> Repo.insert()

    assert <<_::512>> = bot.token
  end

  describe "validations" do
    test "Name must be greater than 3" do
      changeset = Bot.changeset(%Bot{}, %{name: "AA", user_id: @user_id})
      refute changeset.valid?
    end

    test "Name may not be longer than 50" do
      name = :crypto.strong_rand_bytes(26) |> Base.encode16()
      assert String.length(name) > 50
      changeset = Bot.changeset(%Bot{}, %{name: name, user_id: @user_id})
      refute changeset.valid?
    end
  end

  describe "getting a bot" do
    setup do
      {:ok, user} =
        User.changeset(%User{
          id: @user_id,
          github_id: 1,
          name: "TEST"
        })
        |> Repo.insert()

      {:ok, bot} =
        Bot.changeset(%Bot{}, %{
          name: "Test Name",
          user_id: @user_id
        })
        |> Repo.insert()

      %{user: user, bot: bot}
    end

    test "you can get a bot by id", %{bot: %{id: id}} do
      assert nil == Bot.get_by_id(Ecto.UUID.generate())
      assert %Bot{id: ^id} = Bot.get_by_id(id)
    end

    test "you can get a bot by token", %{bot: %{id: id, token: token}} do
      assert nil == Bot.get_by_token("INVALID TOKEN")
      assert %Bot{id: ^id} = Bot.get_by_token(token)
    end

    test "you can preload the user", %{bot: %{id: id}, user: %{id: user_id}} do
      assert %Bot{id: ^id, user: %{id: ^user_id}} =
               Bot.get_by_id(id)
               |> Repo.preload(:user)
    end
  end
end
