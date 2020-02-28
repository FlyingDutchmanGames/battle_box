defmodule BattleBox.BattleBoxGameBot do
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.{BattleBoxGame, Bot}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "game_bots" do
    field :score, :integer, default: 0
    field :player, :string
    belongs_to :bot, Bot
    belongs_to :battle_box_game, BattleBoxGame
    timestamps()
  end

  def changeset(bot, params \\ %{}) do
    bot
    |> cast(params, [:score, :player, :bot_id, :battle_box_game_id])
  end

  def new(opts) do
    opts = Enum.into(opts, %{})

    %__MODULE__{}
    |> Map.merge(opts)
  end
end
