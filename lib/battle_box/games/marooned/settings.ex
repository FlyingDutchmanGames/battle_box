defmodule BattleBox.Games.Marooned.Settings do
  alias BattleBox.Games.Marooned.Types.{Location, PlayerStartingLocations}
  alias BattleBox.Arena
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  def name, do: :marooned_settings

  schema "marooned_settings" do
    belongs_to :arena, Arena

    field :rows, :integer, default: 10
    field :cols, :integer, default: 10
    field :starting_removed_locations, {:array, Location}, default: []
    field :player_starting_locations, PlayerStartingLocations

    timestamps()
  end

  def changeset(settings, params) do
    settings
    |> cast(params, [:rows, :cols])
    |> validate_required([:rows, :cols])
    |> validate_number(:rows, greater_than_or_equal_to: 7, less_than_or_equal_to: 15)
    |> validate_number(:cols, greater_than_or_equal_to: 7, less_than_or_equal_to: 15)
    |> add_starting_locations()
  end

  defp add_starting_locations(changeset) do
    rows = get_field(changeset, :rows)
    cols = get_field(changeset, :cols)
    x = div(cols, 2)

    put_change(changeset, :player_starting_locations, %{1 => [x, 0], 2 => [x, rows - 1]})
  end
end
