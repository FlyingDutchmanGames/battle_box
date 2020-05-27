defmodule BattleBox.Lobby do
  defmodule GameType do
    use Ecto.Type
    import BattleBox.InstalledGames

    def type, do: :string

    for game <- installed_games() do
      def cast(unquote("#{game.name}")), do: {:ok, unquote(game)}
      def cast(unquote(game)), do: {:ok, unquote(game)}
      def load(unquote("#{game.name}")), do: {:ok, unquote(game)}
      def dump(unquote(game)), do: {:ok, unquote("#{game.name}")}
    end
  end

  use Ecto.Schema
  import :timer, only: [seconds: 1]
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

    field :game_type, GameType

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
    |> validate_number(:game_acceptance_time_ms,
      greater_than_or_equal_to: seconds(1),
      less_than: seconds(10)
    )
    |> validate_number(:command_time_minimum_ms,
      greater_than_or_equal_to: milliseconds(250),
      less_than: seconds(1)
    )
    |> validate_number(:command_time_maximum_ms,
      greater_than_or_equal_to: milliseconds(250),
      less_than: seconds(10)
    )
    |> validate_command_time()
    |> unique_constraint(:name)
  end

  def get_settings(lobby) do
    Repo.preload(lobby, :robot_game_settings)
    |> case do
      %{robot_game_settings: robot_game_settings} -> robot_game_settings
    end
  end

  defp validate_command_time(changeset) do
    if get_field(changeset, :command_time_minimum_ms) >=
         get_field(changeset, :command_time_maximum_ms) do
      add_error(
        changeset,
        :command_time_minimum_ms,
        "Minimum command time must be less than maximum command time"
      )
    else
      changeset
    end
  end

  defp milliseconds(milliseconds), do: milliseconds
end
