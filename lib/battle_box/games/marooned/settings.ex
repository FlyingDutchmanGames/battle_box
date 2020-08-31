defmodule BattleBox.Games.Marooned.Settings do
  alias BattleBox.Games.Marooned.Types.Location
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

    timestamps()
  end

  def changeset(settings, params) do
    settings
    |> cast(params, [:rows, :cols])
    |> validate_required([:rows, :cols])
    |> validate_number(:rows, greater_than_or_equal_to: 7, less_than_or_equal_to: 15)
  end
end
