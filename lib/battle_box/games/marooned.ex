defmodule BattleBox.Games.Marooned do
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.Game

  alias __MODULE__.Settings
  alias __MODULE__.Types.{Event, Location, PlayerStartingLocations}

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
    field :next_player, :integer, default: 1

    timestamps()
  end

  def color, do: "orange"
  def view_module, do: BattleBoxWeb.MaroonedView
  def title, do: "Marooned"
  def name, do: :marooned
  def settings_module, do: Settings
  def players_for_settings(_), do: [1, 2]
  def ais, do: []

  def from_settings(%{rows: rows, cols: cols}), do: %__MODULE__{rows: rows, cols: cols}

  def docs_tree, do: %{}

  defimpl BattleBoxGame do
    alias BattleBox.Games.{Marooned, Marooned.Logic}

    def initialize(_game), do: raise("Not Implemented")

    def disqualify(game, player) do
      winner = %{1 => 2, 2 => 1}[player]
      Map.put(game, :winner, winner)
    end

    def settings(game) do
      Map.take(game, [:rows, :cols])
    end

    def commands_requests(game) do
      %{
        game.next_player => %{
          removed_squares: [],
          positions: %{
            1 => [0, 0],
            2 => [1, 1]
          }
        }
      }
    end

    def over?(_game), do: raise("not Implemented")
    def calculate_turn(game, commands), do: Logic.calculate_turn(game, commands)
    def score(_game), do: raise("not Implemented")
    def winner(_game), do: raise("not Implemented")

    def turn_info(_game) do
      raise("Not Implemetned")
    end
  end
end
