defmodule BattleBox.Games.Marooned do
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.Game

  alias __MODULE__.{Settings, Logic}
  alias __MODULE__.Types.{Event, Location, PlayerStartingLocations}
  alias __MODULE__.Ais.WildCard

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "marooned_games" do
    belongs_to :game, Game

    field :turn, :integer, default: 0
    field :rows, :integer, default: 10
    field :cols, :integer, default: 10
    field :events, {:array, Event}, default: []
    field :starting_removed_locations, {:array, Location}, default: []
    field :player_starting_locations, PlayerStartingLocations

    field :winner, :integer, virtual: true
    field :next_player, :integer, default: 1, virtual: true

    timestamps()
  end

  def color, do: "orange"
  def view_module, do: BattleBoxWeb.MaroonedView
  def title, do: "Marooned"
  def name, do: :marooned
  def settings_module, do: Settings
  def players_for_settings(_), do: [1, 2]
  def ais, do: [WildCard]

  def from_settings(%{
        rows: rows,
        cols: cols,
        player_starting_locations: player_starting_locations
      }),
      do: %__MODULE__{
        rows: rows,
        cols: cols,
        player_starting_locations: player_starting_locations
      }

  def docs_tree, do: %{}

  def changeset(game, params \\ %{}) do
    cast(game, params, [])
  end

  defimpl BattleBoxGame do
    alias BattleBox.Games.Marooned.Logic

    def initialize(game), do: game

    def disqualify(game, player) do
      winner = Logic.opponent(player)
      Map.put(game, :winner, winner)
    end

    def settings(game) do
      Map.take(game, [:rows, :cols])
    end

    def commands_requests(game) do
      %{
        game.next_player => %{
          removed_locations: Logic.removed_locations(game),
          player_positions: Logic.player_positions(game),
          turn: game.turn
        }
      }
    end

    def over?(game), do: Logic.over?(game)
    def calculate_turn(game, commands), do: Logic.calculate_turn(game, commands)
    def score(game), do: Logic.score(game)
    def winner(game), do: Logic.winner(game)

    def turn_info(game) do
      max_turn = Enum.max(for(%{turn: turn} <- game.events, do: turn), fn -> 0 end)

      %{
        current_turn: game.turn,
        max_turn: max_turn
      }
    end
  end
end
