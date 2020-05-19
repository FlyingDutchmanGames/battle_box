defmodule BattleBox.ApiKeyTest do
  use BattleBox.DataCase
  alias BattleBox.{ApiKey, Repo}
  import Ecto.Changeset

  @user_id Ecto.UUID.generate()
  @some_time_in_the_past NaiveDateTime.utc_now()
                         |> NaiveDateTime.add(-1_000_000_000)
                         |> NaiveDateTime.truncate(:second)

  describe "validations" do
    test "Name must be greater than 3" do
      changeset = ApiKey.changeset(%ApiKey{}, %{name: "AA"})
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
    setup do
      {:ok, key} =
        ApiKey.changeset(%ApiKey{user_id: @user_id}, %{name: "TEST"})
        |> Repo.insert()

      %{key: key}
    end

    test "it generates a token, a hashed token, and marks the last used value", %{key: key} do
      assert %NaiveDateTime{} = key.last_used
      assert byte_size(key.hashed_token) == 32
      assert byte_size(key.token) == 26
      assert :crypto.hash(:sha256, key.token) == key.hashed_token
    end

    test "you can get a token by its hash (and only its hash)", %{key: key} do
      from_token = ApiKey.from_token(key.token)
      assert key.id == from_token.id
      assert nil == ApiKey.from_token("some random number")
    end

    test "you can mark the updated time", %{key: key} do
      {:ok, key} =
        change(key, last_used: @some_time_in_the_past)
        |> Repo.update()

      assert key.last_used == @some_time_in_the_past
      {:ok, key} = ApiKey.mark_used!(key)
      assert key.last_used != @some_time_in_the_past
      assert NaiveDateTime.diff(NaiveDateTime.utc_now(), key.last_used) < 2
    end
  end
end
