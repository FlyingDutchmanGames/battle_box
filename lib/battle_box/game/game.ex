defmodule BattleBox.Game do
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.{Lobby, Bot, GameBot}
  alias BattleBox.Games.RobotGame.Game, as: RobotGame

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "games" do
    belongs_to :lobby, Lobby
    many_to_many :bots, Bot, join_through: "game_bots"
    has_many :game_bots, GameBot
    has_one :robot_game, RobotGame
    timestamps()
  end

  def changeset(game, params \\ %{}) do
    game
    |> cast(params, [:lobby_id])
    |> cast_assoc(:game_bots)
  end

  def new(opts \\ %{}) do
    %__MODULE__{
      game_bots: opts[:game_bots] || [],
      lobby_id: opts[:lobby_id]
    }
  end
end
