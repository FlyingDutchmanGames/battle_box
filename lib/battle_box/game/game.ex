defmodule BattleBox.Game do
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.{Repo, Lobby, Bot, GameBot}
  alias BattleBox.Games.RobotGame

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "games" do
    belongs_to :lobby, Lobby
    many_to_many :bots, Bot, join_through: "game_bots"
    has_many :game_bots, GameBot
    has_one :robot_game, RobotGame

    timestamps()
  end

  def get_by_id(id) do
    Repo.get_by(__MODULE__, id: id)
  end

  def calculate_turn(game, moves) do
    game = update_in(game.robot_game, &BattleBoxGame.calculate_turn(&1, moves))
    scores = BattleBoxGame.score(game.robot_game)
    winner = BattleBoxGame.winner(game.robot_game)

    update_in(game.game_bots, fn bots ->
      for bot <- bots,
          do: %{
            bot
            | score: scores[bot.player],
              winner: winner == bot.player
          }
    end)
  end

  def compress(game) do
    update_in(game.robot_game, &Map.drop(&1, [:events]))
  end

  def metadata_only(game) do
    Map.drop(game, [:robot_game])
  end

  def persist(game) do
    game
    |> changeset
    |> Repo.insert()
  end

  def changeset(game, params \\ %{}) do
    game
    |> cast(params, [:lobby_id])
    |> cast_assoc(:game_bots)
    |> cast_assoc(:robot_game)
  end

  def new(opts \\ %{}) do
    opts = Enum.into(opts, %{})

    opts =
      Map.merge(%{game_bots: []}, opts)
      |> Map.put_new(:id, Ecto.UUID.generate())

    Map.merge(%__MODULE__{}, opts)
  end
end
