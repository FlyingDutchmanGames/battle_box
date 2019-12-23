defmodule BattleBox.Games.RobotGame.Game.Turn do
  alias BattleBox.Games.RobotGame.Game
  alias BattleBox.Games.RobotGame.Game.Move
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "robot_game_turns" do
    belongs_to :game, Game
    field :turn_number, :integer
    embeds_many :moves, Move

    timestamps()
  end
end
