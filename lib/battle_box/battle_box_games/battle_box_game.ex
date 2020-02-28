defmodule BattleBox.BattleBoxGame do
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.{Lobby, Bot, BattleBoxGameBot}
  alias BattleBox.Games.RobotGame.Game, as: RobotGame
  import Ecto.Query, only: [from: 2]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "battle_box_games" do
    belongs_to :lobby, Lobby
    many_to_many :bots, Bot, join_through: "battle_box_game_players"
    has_many :battle_box_game_bots, BattleBoxGameBot
    has_one :robot_game, RobotGame
    timestamps()
  end

  def changeset(game, params \\ %{}) do
    game
    |> cast(params, [:lobby_id])
    |> cast_assoc(:battle_box_game_bots)
  end

  def new(opts \\ %{}) do
    %__MODULE__{
      battle_box_game_bots: opts[:battle_box_game_bots] || [],
      lobby_id: opts[:lobby_id]
    }
  end

  def base do
    from bbg in __MODULE__, select: bbg
  end
end
