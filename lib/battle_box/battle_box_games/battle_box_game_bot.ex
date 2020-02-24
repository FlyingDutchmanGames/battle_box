defmodule BattleBox.BattleBoxGameBot do
  use Ecto.Schema
  alias BattleBox.{BattleBoxGame, Bot}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "battle_box_game_bots" do
    field :score, :integer, default: 0
    field :player, :string
    belongs_to :bot, Bot
    belongs_to :battle_box_game, BattleBoxGame
    timestamps()
  end
end
