defmodule BattleBox.Game do
  defmodule GameType do
    use Ecto.Type
    import BattleBox.InstalledGames

    def type, do: :string

    for game <- installed_games() do
      def cast(unquote("#{game.name}")), do: {:ok, unquote(game)}
      def cast(unquote(game)), do: {:ok, unquote(game)}
      def load(unquote("#{game.name}")), do: {:ok, unquote(game)}
      def dump(unquote(game)), do: {:ok, unquote("#{game.name}")}
    end
  end

  use Ecto.Schema
  import Ecto.Changeset
  import BattleBox.InstalledGames
  alias BattleBox.{Repo, Arena, Bot, GameBot}
  alias __MODULE__.Gameable

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "games" do
    belongs_to :arena, Arena
    has_many :game_bots, GameBot
    many_to_many :bots, Bot, join_through: "game_bots"

    field :game_type, GameType

    for game_type <- installed_games() do
      has_one(game_type.name, game_type)
    end

    timestamps()
  end

  def build(arena, players) do
    game_bots = for {player, bot} <- players, do: %GameBot{player: player, bot: bot}

    game_data =
      arena
      |> Arena.get_settings()
      |> arena.game_type.from_settings()

    %__MODULE__{
      id: Ecto.UUID.generate(),
      arena: arena,
      arena_id: arena.id,
      game_type: arena.game_type,
      game_bots: game_bots
    }
    |> Map.put(arena.game_type.name, game_data)
  end

  def game_data(game) do
    Map.get(game, game.game_type.name)
  end

  def calculate_turn(game, commands) do
    %{game: after_turn, debug: debug, info: info} =
      Gameable.calculate_turn(game_data(game), commands)

    game = update_game_data(game, fn _ -> after_turn end)

    scores = score(game)
    winner = winner(game)

    game =
      update_in(game.game_bots, fn bots ->
        for bot <- bots,
            do: %{
              bot
              | score: scores[bot.player],
                winner: winner == bot.player
            }
      end)

    %{game: game, debug: debug, info: info}
  end

  def changeset(game, params \\ %{}) do
    game
    |> cast(params, [:game_type])
    |> validate_inclusion(:game_type, installed_games())
    |> cast_assoc(:game_bots)
    |> cast_assoc(game.game_type.name)
  end

  def preload_game_data(nil), do: nil

  def preload_game_data(game) do
    Repo.preload(game, game.game_type.name)
  end

  def initialize(game) do
    update_game_data(game, &Gameable.initialize/1)
  end

  def score(game) do
    game |> game_data |> Gameable.score()
  end

  def winner(game) do
    game |> game_data |> Gameable.winner()
  end

  def commands_requests(game) do
    game |> game_data |> Gameable.commands_requests()
  end

  def over?(game) do
    game |> game_data |> Gameable.over?()
  end

  def disqualify(game, player) do
    update_game_data(game, &Gameable.disqualify(&1, player))
  end

  def turn_info(game) do
    game |> game_data() |> Gameable.turn_info()
  end

  def settings(game) do
    game |> game_data() |> Gameable.settings()
  end

  def metadata_only(game) do
    Map.drop(game, [game.game_type.name])
  end

  defp update_game_data(game, fun) do
    new_game_data =
      game
      |> game_data()
      |> fun.()

    Map.put(game, game.game_type.name, new_game_data)
  end
end
