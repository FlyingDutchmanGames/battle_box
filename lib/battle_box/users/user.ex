defmodule BattleBox.User do
  use Ecto.Schema
  alias BattleBox.{Repo, Bot}
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @params [
    :name,
    :github_id,
    :github_avatar_url,
    :github_html_url,
    :github_login_name,
    :github_access_token
  ]

  schema "users" do
    field :name, :string
    field :github_id, :integer
    field :github_avatar_url, :string
    field :github_html_url, :string
    field :github_login_name, :string
    field :github_access_token, :string
    has_many :bots, Bot

    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, @params)
    |> validate_required([:name, :github_id])
    |> unique_constraint(:github_id)
  end

  def upsert_from_github(user_data) do
    %{
      "avatar_url" => github_avatar_url,
      "html_url" => github_html_url,
      "id" => github_id,
      "login" => github_login_name,
      "name" => name,
      "access_token" => token
    } = user_data

    changeset(%__MODULE__{}, %{
      name: name,
      github_avatar_url: github_avatar_url,
      github_html_url: github_html_url,
      github_id: github_id,
      github_login_name: github_login_name,
      github_access_token: token
    })
    |> Repo.insert(
      returning: true,
      conflict_target: [:github_id],
      on_conflict:
        {:replace,
         [
           :name,
           :github_avatar_url,
           :github_html_url,
           :github_id,
           :github_login_name,
           :updated_at
         ]}
    )
  end

  def get_by_github_id(id) do
    Repo.get_by(__MODULE__, github_id: id)
  end

  def get_by_id(id) do
    Repo.get_by(__MODULE__, id: id)
  end
end
