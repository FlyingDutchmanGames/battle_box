defmodule BattleBox.Games.RobotGame.Game.Turn do
  alias BattleBox.Games.RobotGame.Game
  alias BattleBox.Games.RobotGame.Game.Event
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id

  schema "robot_game_turns" do
    belongs_to :game, Game, primary_key: true
    field :turn_number, :integer, primary_key: true
    embeds_many :events, Event

    timestamps()
  end

  def changeset(turn, params \\ %{}) do
    turn
    |> cast(params, [:turn_number, :game_id])
    |> cast_embed(:events)
  end
end
