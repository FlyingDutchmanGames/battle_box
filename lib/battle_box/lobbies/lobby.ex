defmodule BattleBox.Lobby do
  use Ecto.Schema
  import Ecto.Changeset
  import BattleBox.InstalledGames
  alias BattleBox.{Repo, User, Game}

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
    field :game_acceptance_time_ms, :integer, default: 2000
    field :command_time_minimum_ms, :integer, default: 250
    field :command_time_maximum_ms, :integer, default: 1000

    field :game_type, BattleBox.GameType

    has_many :games, Game
    belongs_to :user, User

    for game_type <- installed_games() do
      has_one(game_type.settings_module.name, game_type.settings_module)
    end

    timestamps()
  end

  def changeset(lobby, params \\ %{}) do
    lobby
    |> cast(params, @params)
    |> validate_required(@params)
    |> validate_inclusion(:game_type, installed_games())
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
