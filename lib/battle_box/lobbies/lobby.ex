defmodule BattleBox.Lobby do
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.{GameType, Repo, User, Game}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @params [
    :name,
    :game_type,
    :game_acceptance_time_ms,
    :command_time_minimum_ms,
    :command_time_maximum_ms
  ]

  schema "lobbies" do
    field :name, :string
    field :game_type, GameType
    field :game_acceptance_time_ms, :integer, default: 2000
    field :command_time_minimum_ms, :integer, default: 250
    field :command_time_maximum_ms, :integer, default: 1000

    has_many :games, Game
    belongs_to :user, User

    for game_type <- GameType.game_types() do
      has_one(game_type.settings_module.name, game_type.settings_module)
    end

    timestamps()
  end

  def changeset(lobby, params \\ %{}) do
    lobby
    |> cast(params, @params)
    |> validate_required(@params)
    |> validate_inclusion(:game_type, GameType.game_types())
    |> validate_length(:name, max: 50)
    |> unique_constraint(:name)
    |> cast_assoc(:robot_game_settings)
  end

  def get_settings(lobby) do
    Repo.preload(lobby, :robot_game_settings)
    |> case do
      %{robot_game_settings: robot_game_settings} -> robot_game_settings
    end
  end
end
