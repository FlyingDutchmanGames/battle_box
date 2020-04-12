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

  def calculate_turn(game, commands) do
    game = update_in(game.robot_game, &BattleBoxGame.calculate_turn(&1, commands))
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

  def initialize(game) do
    update_in(game.robot_game, &BattleBoxGame.initialize/1)
  end

  def score(game) do
    BattleBoxGame.score(game.robot_game)
  end

  def winner(game) do
    BattleBoxGame.winner(game.robot_game)
  end

  def commands_requests(game) do
    BattleBoxGame.commands_requests(game.robot_game)
  end

  def over?(game) do
    BattleBoxGame.over?(game.robot_game)
  end

  def disqualify(game, player) do
    update_in(game.robot_game, &BattleBoxGame.disqualify(&1, player))
  end

  def settings(game) do
    BattleBoxGame.settings(game.robot_game)
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
