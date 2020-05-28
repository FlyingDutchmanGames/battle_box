defmodule BattleBox.ApiKeyTest do
  use BattleBox.DataCase
  alias BattleBox.{ApiKey, User, Repo}

  @user_id Ecto.UUID.generate()

  setup do
    {:ok, user} = create_user(id: @user_id)

    {:ok, key} =
      user
      |> Ecto.build_assoc(:api_keys)
      |> ApiKey.changeset(%{name: "TEST"})
      |> Repo.insert()

    %{key: key, user: user}
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
  end

  describe "authenticate" do
    test "a valid token works and it updates the last_used field", %{key: key, user: %{id: id}} do
      assert key.last_used == nil
      assert {:ok, %{id: ^id}} = ApiKey.authenticate(key.token)
      key = Repo.get(ApiKey, key.id)
      assert NaiveDateTime.diff(NaiveDateTime.utc_now(), key.last_used) < 2
    end

    test "A banned user is banned", %{key: key, user: user} do
      {:ok, _user} = User.set_ban_status(user, true)
      assert {:error, %{user: ["User is banned"]}} == ApiKey.authenticate(key.token)
    end

    test "an invalid token doesn't work" do
      assert {:error, %{token: ["API Key Invalid"]}} == ApiKey.authenticate("INVALID_TOKEN")
    end
  end
end
