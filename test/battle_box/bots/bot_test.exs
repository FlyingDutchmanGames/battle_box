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

    assert <<_::256>> = bot.token
  end

  describe "validations" do
    test "Name must be greater than 3" do
      changeset = Bot.changeset(%Bot{}, %{name: "AA", user_id: @user_id})
      refute changeset.valid?
    end

    test "Name may not be longer than 20" do
      name = :crypto.strong_rand_bytes(11) |> Base.encode16()
      assert String.length(name) > 20
      changeset = Bot.changeset(%Bot{}, %{name: name, user_id: @user_id})
      refute changeset.valid?
    end
  end

  describe "getting a bot" do
    setup do
      {:ok, user} = create_user(id: @user_id)

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

    test "you can use the by identifier", %{bot: %{id: id} = bot} do
      assert nil == Bot.get_by_identifier(nil)
      assert %{id: ^id} = Bot.get_by_identifier(id)
      assert %{id: ^id} = Bot.get_by_identifier(bot.name)
    end
  end

  describe "banned?" do
    test "a bot without a user is not banned" do
      refute Bot.banned?(%Bot{})
    end

    test "A bot with a user who isn't banned isn't banned" do
      refute Bot.banned?(%Bot{user: %User{is_banned: false}})
    end

    test "A bot with a user who is banned is banned" do
      assert Bot.banned?(%Bot{user: %User{is_banned: true}})
    end
  end
end
