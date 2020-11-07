defmodule BattleBox.GameBot do
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.{Game, Bot}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "game_bots" do
    field :score, :integer, default: 0
    field :player, :integer
    field :winner, :boolean, default: false
    belongs_to :bot, Bot
    belongs_to :game, Game
    timestamps()
  end

  def changeset(bot, params \\ %{}) do
    bot
    |> cast(params, [:score, :player, :winner])
  end
end
