defmodule BattleBox.ApiKey do
  alias BattleBox.{Repo, User, Bot}
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Inspect, except: [:hashed_token]}
  schema "api_keys" do
    field :name, :binary
    field :token, :string, virtual: true
    field :hashed_token, :binary
    field :last_used, :naive_datetime
    belongs_to :user, User
    timestamps()
  end

  def changeset(api_key, params) do
    token = gen_token()

    api_key
    |> cast(params, [:name])
    |> validate_required(:name)
    |> validate_length(:name, max: 30)
    |> put_change(:token, token)
    |> put_change(:hashed_token, hash(token))
  end

  def authenticate(token) do
    Repo.get_by(__MODULE__, hashed_token: hash(token))
    |> Repo.preload(:user)
    |> case do
      nil ->
        {:error, %{token: ["API Key Invalid"]}}

      %__MODULE__{user: %User{is_banned: true}} ->
        {:error, %{user: ["User is banned"]}}

      %__MODULE__{user: %User{} = user} = key ->
        mark_used!(key)
        {:ok, user}
    end
  end

  defp mark_used!(%__MODULE__{} = api_key) do
    api_key
    |> change(last_used: now())
    |> Repo.update()
  end

  def gen_token do
    :crypto.strong_rand_bytes(16)
    |> Base.encode32(padding: false, case: :lower)
  end

  defp hash(token) do
    # Normally when you hash passwords you want to use a much stronger/slower
    # hash function like argon2. Since API keys are 128 bits of strong random
    # bytes and not a short user generated phrase, we're safe to use a much faster
    # hash function. There's a 0% chance of brute forcing 128 random bits
    :crypto.hash(:sha256, token)
  end

  def now do
    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  end
end
