defmodule BattleBox.User do
  use Ecto.Schema
  alias BattleBox.{Repo, Bot, Lobby, ApiKey}
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :github_id, :integer
    field :avatar_url, :string
    field :user_name, :string

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
      user_name: user_data["login"],
      avatar_url: user_data["avatar_url"]
    )
    |> Repo.insert(
      returning: true,
      conflict_target: [:github_id],
      on_conflict: {:replace, [:avatar_url, :user_name, :updated_at]}
    )
  end

  def set_ban_status(%__MODULE__{} = user, status) do
    user
    |> change(is_banned: status)
    |> Repo.update()
  end
end
