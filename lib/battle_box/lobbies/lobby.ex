defmodule BattleBox.Lobby do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias BattleBox.{Repo, User, BattleBoxGame}
  alias __MODULE__.GameType

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @game_types Application.compile_env(:battle_box, [BattleBox.GameEngine, :games]) ||
                raise("Must set the :battle_box, BattleBox.GameEngine, :games config value")

  @params [
    :name,
    :game_type,
    :game_acceptance_timeout_ms,
    :user_id
  ]

  schema "lobbies" do
    field :name, :string
    field :game_type, GameType
    field :game_acceptance_timeout_ms, :integer, default: 2000
    has_many :battle_box_games, BattleBoxGame
    belongs_to :user, User

    timestamps()
  end

  def changeset(lobby, params \\ %{}) do
    lobby
    |> cast(params, @params)
    |> validate_required(@params)
    |> validate_inclusion(:game_type, @game_types)
    |> validate_length(:name, min: 3, max: 50)
    |> unique_constraint(:name)
  end

  def base() do
    from lobby in __MODULE__, as: :lobby
  end

  def create(params) do
    changeset(%__MODULE__{}, params)
    |> Repo.insert()
  end

  def with_user_id(query \\ nil, user_id) do
    query = query || base()
    from lobby in query, where: lobby.user_id == ^user_id
  end

  def get_by_name(name) do
    Repo.get_by(__MODULE__, name: name)
  end

  def get_by_id(id) do
    Repo.get_by(__MODULE__, id: id)
  end
end
