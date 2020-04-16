defmodule BattleBox.Lobby do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi
  alias BattleBox.{Repo, User, Game}
  alias __MODULE__.GameType

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @game_types Application.get_env(:battle_box, BattleBox.GameEngine)[:games] ||
                raise("Must set the :battle_box, BattleBox.GameEngine, :games config value")

  @game_settings_modules Enum.map(@game_types, fn game_type -> game_type.settings_module() end)

  @params [
    :name,
    :game_type,
    :game_acceptance_time_ms,
    :command_time_minimum_ms,
    :command_time_maximum_ms,
    :user_id,
    :settings_id
  ]

  schema "lobbies" do
    field :name, :string
    field :game_type, GameType
    field :game_acceptance_time_ms, :integer, default: 2000
    field :command_time_minimum_ms, :integer, default: 250
    field :command_time_maximum_ms, :integer, default: 1000
    field :settings_id, :binary_id
    has_many :games, Game
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

  def get_settings(lobby) do
    lobby.game_type.settings_module.get_by_id(lobby.settings_id)
  end

  def create(params) do
    {:ok, game_type} = GameType.cast(params[:game_type] || params["game_type"])
    settings_module = game_type.settings_module()

    settings =
      case params[:settings] do
        %{__struct__: struct} = settings when struct in @game_settings_modules -> settings
        settings -> settings_module.new(settings || %{})
      end
      |> Map.put_new(:id, Ecto.UUID.generate())

    settings_changeset = settings_module.changeset(settings)
    lobby_changeset = changeset(%__MODULE__{settings_id: settings.id}, params)

    Multi.new()
    |> Multi.insert_or_update(:settings, settings_changeset)
    |> Multi.insert(:lobby, lobby_changeset)
    |> Repo.transaction()
    |> case do
      {:ok, %{lobby: lobby}} -> {:ok, lobby}
      {:error, :lobby, changeset, _} -> {:error, changeset}
    end
  end

  def with_user_id(query \\ nil, user_id) do
    query = query || base()
    from lobby in query, where: lobby.user_id == ^user_id
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
