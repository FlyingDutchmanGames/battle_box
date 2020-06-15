defmodule BattleBox.User do
  use Ecto.Schema
  alias BattleBox.{Repo, Bot, Lobby, ApiKey}
  import Ecto.Changeset
  import BattleBox.Utilities.UserIdentifierValidation, only: [validate_user_identifer: 2]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :github_id, :integer
    field :avatar_url, :string
    field :username, :string

    field :connection_limit, :integer, default: 10

    field :is_admin, :boolean, default: false
    field :is_banned, :boolean, default: false

    has_many :bots, Bot
    has_many :lobbies, Lobby
    has_many :api_keys, ApiKey

    timestamps()
  end

  def upsert_from_github(user_data) do
    change(%__MODULE__{},
      github_id: user_data["id"],
      username: user_data["login"],
      avatar_url: user_data["avatar_url"]
    )
    |> Repo.insert(
      returning: true,
      conflict_target: [:github_id],
      on_conflict: {:replace, [:avatar_url, :username, :updated_at]}
    )
  end

  def admin_changeset(user, params \\ %{}) do
    user
    |> cast(params, [:username, :avatar_url, :is_admin, :is_banned, :connection_limit])
    |> validate_required([:username, :avatar_url, :is_admin, :is_admin, :connection_limit])
    |> validate_number(:connection_limit, greater_than: 0)
    |> validate_user_identifer(:username)
    |> unique_constraint(:username)
  end
end
