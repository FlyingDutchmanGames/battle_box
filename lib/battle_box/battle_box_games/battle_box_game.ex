defmodule BattleBox.BattleBoxGame do
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.{Lobby, Bot, BattleBoxGameBot}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "battle_box_games" do
    belongs_to :winner, Bot
    belongs_to :lobby, Lobby
    many_to_many :bots, Bot, join_through: "battle_box_game_players"
    has_many :battle_box_game_bots, BattleBoxGameBot
    timestamps()
  end

  def changeset(game, params \\ %{}) do
    game
    |> cast(params, [:lobby_id, :winner_id])
  end

  def build(%{lobby: lobby, players: players}) do
    id = Ecto.UUID.generate()
    game = Ecto.build_assoc(lobby, :battle_box_games, %{id: Ecto.UUID.generate()})

    bots =
      for {player, bot_id} <- players do
        Ecto.build_assoc(game, :battle_box_game_bots, %{bot_id: bot_id, player: player})
      end

    change(game, battle_box_game_bots: bots)
  end
end
