defmodule BattleBox.User do
  use Ecto.Schema
  alias BattleBox.{Repo, Bot}
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @params [
    :github_id,
    :github_avatar_url,
    :github_login_name,
    :is_admin,
    :is_banned
  ]

  schema "users" do
    field :github_id, :integer
    field :github_avatar_url, :string
    field :github_login_name, :string
    field :is_admin, :boolean, default: false
    field :is_banned, :boolean, default: false
    has_many :bots, Bot

    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, @params)
    |> validate_required([:github_id, :github_avatar_url, :github_login_name])
    |> unique_constraint(:github_id)
  end

  def upsert_from_github(user_data) do
    %{
      "avatar_url" => github_avatar_url,
      "id" => github_id,
      "login" => github_login_name
    } = user_data

    changeset(%__MODULE__{}, %{
      github_avatar_url: github_avatar_url,
      github_id: github_id,
      github_login_name: github_login_name
    })
    |> Repo.insert(
      returning: true,
      conflict_target: [:github_id],
      on_conflict:
        {:replace,
         [
           :github_avatar_url,
           :github_id,
           :github_login_name,
           :updated_at
         ]}
    )
  end

  def get_by_github_id(id) do
    Repo.get_by(__MODULE__, github_id: id)
  end

  def get_by_id(<<_::288>> = id) do
    Repo.get_by(__MODULE__, id: id)
  end

  def get_by_id(_), do: nil

  def get_by_identifier(nil), do: nil
  def get_by_identifier(<<_::288>> = uuid), do: get_by_id(uuid)
  def get_by_identifier(name), do: get_by_github_login_name(name)

  def get_by_github_login_name(login_name) do
    Repo.get_by(__MODULE__, github_login_name: login_name)
  end

  def set_ban_status(%__MODULE__{} = user, status) do
    changeset = change(user, is_banned: status)
    Repo.update(changeset)
  end
end
