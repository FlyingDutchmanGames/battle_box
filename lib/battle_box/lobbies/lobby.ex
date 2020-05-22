defmodule BattleBox.Lobby do
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.{Repo, User, Game}
  alias __MODULE__.GameType

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @game_types Application.get_env(:battle_box, BattleBox.GameEngine)[:games] ||
                raise("Must set the :battle_box, BattleBox.GameEngine, :games config value")

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

    for game_type <- @game_types do
      has_one(game_type.settings_module.name, game_type.settings_module)
    end

    timestamps()
  end

  def changeset(lobby, params \\ %{}) do
    lobby
    |> cast(params, @params)
    |> validate_required(@params)
    |> validate_inclusion(:game_type, @game_types)
    |> validate_length(:name, max: 50)
    |> unique_constraint(:name)
    |> cast_assoc(:robot_game_settings)
  end

  def game_types, do: @game_types
end
