defmodule BattleBox.Games.Marooned do
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.Game

  alias __MODULE__.Settings

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "marooned_games" do
    belongs_to :game, Game

    field :rows, :integer, default: 10
    field :cols, :integer, default: 10

    timestamps()
  end

  def color, do: "orange"
  def view_module, do: BattleBoxWeb.MaroonedView
  def title, do: "Marooned"
  def name, do: :marooned
  def settings_module, do: Settings
  def players_for_settings(_), do: [1, 2]
  def ais, do: []

  def docs_tree, do: %{}

  defimpl BattleBoxGame do
    # alias BattleBox.Games.Marooned

    def initialize(_game), do: raise("Not Implemented")
    def disqualify(_game, _player), do: raise("Not Implemented")
    def over?(_game), do: raise("not Implemented")
    def settings(_game), do: raise("not Implemented")
    def commands_requests(_game), do: raise("not Implemented")
    def calculate_turn(_game, _commands), do: raise("not Implemented")
    def score(_game), do: raise("not Implemented")
    def winner(_game), do: raise("not Implemented")
  end
end
