defmodule BattleBox.Bot do
  alias BattleBox.User
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias BattleBox.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @params [
    :name,
    :user_id
  ]

  schema "bots" do
    field :name, :string
    field :token, :string, autogenerate: {__MODULE__, :generate_token, []}
    belongs_to :user, User

    timestamps()
  end

  def changeset(bot, params \\ %{}) do
    bot
    |> cast(params, @params)
    |> validate_required(@params)
    |> validate_length(:name, min: 3, max: 50)
    |> unique_constraint(:name, name: "bots_user_id_name_index")
    |> unique_constraint(:token)
  end

  def create(params) do
    changeset(%__MODULE__{}, params)
    |> Repo.insert()
  end

  def with_user_id(user_id) do
    Repo.all(
      from bot in __MODULE__,
        where: bot.user_id == ^user_id,
        select: bot
    )
  end

  def get_by_id(id) do
    Repo.get_by(__MODULE__, id: id)
  end

  def get_by_token(token) do
    Repo.get_by(__MODULE__, token: token)
  end

  def generate_token() do
    :crypto.strong_rand_bytes(32)
    |> Base.encode16()
    |> String.downcase()
  end
end
