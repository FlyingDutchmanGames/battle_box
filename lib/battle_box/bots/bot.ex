defmodule BattleBox.Bot do
  alias BattleBox.{User, Game}
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
    many_to_many :games, Game, join_through: "game_bots"
    belongs_to :user, User

    timestamps()
  end

  def changeset(bot, params \\ %{}) do
    bot
    |> cast(params, @params)
    |> validate_required(@params)
    |> validate_length(:name, min: 3, max: 20)
    |> unique_constraint(:name)
    |> unique_constraint(:token)
  end

  def create(params) do
    changeset(%__MODULE__{}, params)
    |> Repo.insert()
  end

  def with_user_id(query \\ nil, user_id) do
    query = query || base()
    from bot in query, where: bot.user_id == ^user_id
  end

  def get_by_token(token) do
    Repo.get_by(__MODULE__, token: token)
  end

  def banned?(bot) do
    bot = Repo.preload(bot, :user)

    case bot.user do
      %User{is_banned: true} -> true
      _ -> false
    end
  end

  def generate_token() do
    :crypto.strong_rand_bytes(20)
    |> Base.encode32()
    |> String.downcase()
  end

  defp base do
    from bot in __MODULE__, as: :bot
  end

  def get_by_identifier(nil), do: nil
  def get_by_identifier(<<_::288>> = uuid), do: get_by_id(uuid)
  def get_by_identifier(name), do: get_by_name(name)

  def get_by_name(name) do
    Repo.get_by(__MODULE__, name: name)
  end

  def get_by_id(id) do
    Repo.get_by(__MODULE__, id: id)
  end
end
