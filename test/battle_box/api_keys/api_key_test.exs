defmodule BattleBox.ApiKeyTest do
  use BattleBox.DataCase
  alias BattleBox.{ApiKey, Bot, User, Repo}

  @user_id Ecto.UUID.generate()

  setup do
    {:ok, user} = create_user(id: @user_id)

    {:ok, key} =
      user
      |> Ecto.build_assoc(:api_keys)
      |> ApiKey.changeset(%{name: "TEST"})
      |> Repo.insert()

    {:ok, bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "BOT"})
      |> Repo.insert()

    %{key: key, bot: bot, user: user}
  end

  describe "validations" do
    test "Name must be greater than 1" do
      changeset = ApiKey.changeset(%ApiKey{}, %{name: ""})
      refute changeset.valid?
    end

    test "Name may not be longer than 30" do
      name = :crypto.strong_rand_bytes(16) |> Base.encode16()
      assert String.length(name) > 30
      changeset = ApiKey.changeset(%ApiKey{}, %{name: name})
      refute changeset.valid?
    end
  end

  describe "Token Manipulation" do
    test "it generates a token, a hashed token, and no last used value", %{key: key} do
      assert key.last_used == nil
      assert byte_size(key.hashed_token) == 32
      assert byte_size(key.token) == 26
      assert :crypto.hash(:sha256, key.token) == key.hashed_token
    end

    test "you can get a token by its hash (and only its hash)", %{key: key} do
      from_token = ApiKey.from_token(key.token)
      assert key.id == from_token.id
      assert nil == ApiKey.from_token("some random number")
      assert nil == ApiKey.from_token(key.hashed_token)
    end
  end

  describe "authenticate_bot" do
    test "a valid token and bot work, and it updates the last_used field", %{
      key: key,
      bot: %{id: id, name: name}
    } do
      assert key.last_used == nil
      assert {:ok, %{id: ^id}} = ApiKey.authenticate_bot(key.token, name)
      key = Repo.get(ApiKey, key.id)
      assert NaiveDateTime.diff(NaiveDateTime.utc_now(), key.last_used) < 2
    end

    test "A banned user is banned", %{key: key, bot: bot, user: user} do
      {:ok, _user} = User.set_ban_status(user, true)
      assert {:error, :banned} = ApiKey.authenticate_bot(key.token, bot.name)
    end

    test "A non existant bot doesnt work", %{key: key} do
      assert {:error, :bot_not_found} = ApiKey.authenticate_bot(key.token, "SOME BOT")
    end

    test "an invalid token doesn't work" do
      assert {:error, :invalid_token} = ApiKey.authenticate_bot("INVALID_TOKEN", "SOME BOT")
    end
  end
end
