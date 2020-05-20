defmodule BattleBox.Bot do
  alias BattleBox.{User, Game}
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "bots" do
    field :name, :string
    many_to_many :games, Game, join_through: "game_bots"
    belongs_to :user, User
    timestamps()
  end

  def changeset(bot, params \\ %{}) do
    bot
    |> cast(params, [:name])
    |> validate_required(:name)
    |> validate_length(:name, max: 20)
    |> unique_constraint(:name)
  end

  def get_by_name(name) do
    Repo.get_by(__MODULE__, name: name)
  end

  def get_by_id(id) do
    Repo.get_by(__MODULE__, id: id)
  end
end
