defmodule BattleBox.Games.RobotGame.Game do
  alias BattleBox.{Repo, BattleBoxGame}
  alias BattleBox.Games.RobotGame.{Settings, Settings.DamageModifier}
  alias __MODULE__.Event
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "robot_games" do
    field :turn, :integer, default: 0
    embeds_many :events, Event, on_replace: :delete
    field :winner, :string, virtual: true
    field :move_time_ms, :integer, virtual: true, default: 5000

    belongs_to :settings, Settings
    belongs_to :battle_box_game, BattleBoxGame

    timestamps()
  end

  def changeset(game, params \\ %{}) do
    game
    |> Repo.preload([:settings, :battle_box_game])
    |> cast(params, [
      :winner,
      :turn,
      :settings_id,
      :battle_box_game_id
    ])
    |> cast_embed(:events)
    |> cast_assoc(:battle_box_game)
  end

  def db_name, do: "robot_game"

  def get_by_id_with_settings(id), do: Repo.preload(get_by_id(id), :settings)
  def get_by_id(<<_::288>> = id), do: Repo.get_by(__MODULE__, id: id)
  def get_by_id(_), do: nil

  def disqualify(game, player) do
    winner = %{"player_1" => "player_2", "player_2" => "player_1"}[player]
    Map.put(game, :winner, winner)
  end

  def persist(%{settings: %{persistent?: false}} = game), do: {:ok, game}

  def persist(game) do
    scores = score(game)

    game =
      update_in(game.battle_box_game.battle_box_game_bots, fn bots ->
        for bot <- bots, do: %{bot | score: scores[bot.player]}
      end)

    events = Enum.map(game.events, &Map.take(&1, [:turn, :seq_num, :cause, :effects]))

    game
    |> Map.put(:events, events)
    |> changeset()
    |> Repo.insert(on_conflict: :replace_all, conflict_target: :id)
  end

  def validate_moves(game, moves, player) do
    moves
    |> Enum.uniq_by(fn move -> move["robot_id"] end)
    |> Enum.filter(fn move -> match?(%{player_id: ^player}, get_robot(game, move["robot_id"])) end)
  end

  def calculate_winner(game) do
    if over?(game) do
      scores = score(game)

      winner =
        case {scores["player_1"], scores["player_2"]} do
          {p1, p2} when p1 == p2 -> nil
          {p1, p2} when p1 > p2 -> "player_1"
          {p1, p2} when p1 < p2 -> "player_2"
        end

      %{game | winner: winner}
    else
      game
    end
  end

  def complete_turn(game),
    do: update_in(game.turn, &(&1 + 1))

  def put_events(game, events),
    do: Enum.reduce(events, game, &put_event(&2, &1))

  def put_event(game, event) do
    seq_num =
      game.events
      |> Enum.map(fn event -> event.seq_num end)
      |> Enum.max(fn -> 0 end)
      |> Kernel.+(1)

    event = Map.merge(%{turn: game.turn, seq_num: seq_num}, event)
    update_in(game.events, &[event | &1])
  end

  def apply_effects_to_robots(robots, effects),
    do: Enum.reduce(effects, robots, &apply_effect_to_robots(&2, &1))

  def apply_effect_to_robots(robots, effect) do
    case effect do
      ["move", robot_id, location] ->
        Enum.map(robots, fn
          %{id: ^robot_id} = robot -> put_in(robot.location, location)
          robot -> robot
        end)

      ["damage", robot_id, amount] ->
        Enum.map(robots, fn
          %{id: ^robot_id, hp: hp} = robot -> %{robot | hp: hp - amount}
          robot -> robot
        end)

      ["guard", _robot_id] ->
        robots

      ["create_robot", player_id, robot_id, hp, location] ->
        [%{player_id: player_id, location: location, id: robot_id, hp: hp} | robots]

      ["remove_robot", robot_id] ->
        Enum.reject(robots, fn robot -> robot.id == robot_id end)
    end
  end

  def new(opts \\ []) do
    settings =
      case opts[:settings] do
        nil -> Settings.new()
        %Settings{} = settings -> settings
        %{} = settings -> Settings.new(settings)
      end

    bbg =
      case opts[:battle_box_game] do
        nil -> BattleBoxGame.new()
        %BattleBoxGame{} = bbg -> bbg
      end

    opts = Enum.into(opts, %{})
    opts = Map.put_new(opts, :id, Ecto.UUID.generate())
    opts = Map.merge(opts, %{settings: settings, battle_box_game: bbg})

    %__MODULE__{}
    |> Map.merge(opts)
  end

  def over?(game), do: game.winner || game.turn >= game.settings.max_turns

  def score(game) do
    robot_score =
      robots(game)
      |> Enum.frequencies_by(fn robot -> robot.player_id end)

    Map.merge(%{"player_1" => 0, "player_2" => 0}, robot_score)
  end

  def dimensions(game), do: Settings.Terrain.dimensions(game.settings.terrain)

  def spawns(game), do: Settings.Terrain.spawn(game.settings.terrain)

  def robots(game), do: robots_at_turn(game, game.turn)

  def robots_at_turn(game, turn) do
    events =
      game.events
      |> Enum.filter(fn event -> event.turn <= turn end)
      |> Enum.sort_by(fn event -> event.seq_num end)
      |> Enum.flat_map(fn event -> event.effects end)

    apply_effects_to_robots([], events)
  end

  def spawning_round?(game),
    do: game.settings.spawn_enabled && rem(game.turn, game.settings.spawn_every) == 0

  def get_robot(%__MODULE__{} = game, id), do: get_robot(robots(game), id)

  def get_robot(robots, id) when is_list(robots),
    do: Enum.find(robots, fn robot -> robot.id == id end)

  def get_robot_at_location(%__MODULE__{} = game, location),
    do: get_robot_at_location(robots(game), location)

  def get_robot_at_location(robots, location) when is_list(robots),
    do: Enum.find(robots, fn robot -> robot.location == location end)

  def available_adjacent_locations(game, location) do
    Enum.filter(adjacent_locations(location), &(game.settings.terrain[&1] in [:normal, :spawn]))
  end

  def adjacent_locations([row, col]),
    do: [
      [row + 1, col],
      [row - 1, col],
      [row, col + 1],
      [row, col - 1]
    ]

  def guarded_attack_damage(game), do: Integer.floor_div(attack_damage(game), 2)
  def attack_damage(game), do: DamageModifier.calc_damage(game.settings.attack_damage)

  def guarded_suicide_damage(game), do: Integer.floor_div(suicide_damage(game), 2)
  def suicide_damage(game), do: DamageModifier.calc_damage(game.settings.suicide_damage)

  def guarded_collision_damage(_game), do: 0
  def collision_damage(game), do: DamageModifier.calc_damage(game.settings.collision_damage)

  def moves_request(game) do
    %{robots: robots(game), turn: game.turn}
  end

  def settings(game) do
    Map.take(game.settings, [
      :spawn_every,
      :spawn_per_player,
      :robot_hp,
      :max_turns,
      :attack_damage,
      :collision_damage
      # :terrain,
    ])
  end
end

defimpl BattleBoxGame, for: BattleBox.Games.RobotGame.Game do
  alias BattleBox.Games.RobotGame.Game
  def id(game), do: game.id
  def disqualify(game, player), do: Game.disqualify(game, player)
  def over?(game), do: Game.over?(game)
  def persist(game), do: Game.persist(game)
  def settings(game), do: Game.settings(game)
  def moves_request(game), do: Game.moves_request(game)
  def calculate_turn(game, moves), do: Game.Logic.calculate_turn(game, moves)
  def move_time_ms(game), do: game.move_time_ms
  def score(game), do: Game.score(game)
  def winner(game), do: game.winner
end
