defmodule BattleBox.Games.RobotGame do
  import BattleBox.Games.RobotGame.EventHelpers
  import Ecto.Changeset
  require __MODULE__.Settings.Shared
  alias BattleBox.Game
  alias __MODULE__.{Settings, Event}
  alias __MODULE__.Settings.{Terrain, DamageModifier}
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "robot_games" do
    field :turn, :integer, default: 0
    field :events, {:array, Event}, default: []
    belongs_to :game, Game

    field :winner, :string, virtual: true
    field :robots_at_end_of_turn, :map, virtual: true, default: %{-1 => []}
    field :robot_id_seq, :integer, default: 0, virtual: true
    field :spawn_enabled, :boolean, default: true, virtual: true

    Settings.Shared.fields()
    timestamps()
  end

  def changeset(game, params \\ %{}) do
    cast(game, params, [:turn, :events])
  end

  def color, do: "green"
  def view, do: BattleBoxWeb.RobotGameView
  def title, do: "Robot Game"
  def name, do: :robot_game
  def settings_module, do: Settings
  def players_for_settings(_), do: [1, 2]

  def disqualify(game, player) do
    winner = %{1 => 2, 2 => 1}[player]
    Map.put(game, :winner, winner)
  end

  def validate_moves(_game, :timeout, _player), do: []

  def validate_moves(game, moves, player) do
    moves
    |> Enum.uniq_by(fn move -> move["robot_id"] end)
    |> Enum.filter(fn move -> match?(%{player_id: ^player}, get_robot(game, move["robot_id"])) end)
  end

  def next_robot_id(game), do: {update_in(game.robot_id_seq, &(&1 + 1)), game.robot_id_seq}

  def calculate_winner(game) do
    if over?(game) do
      scores = score(game)

      winner =
        case {scores[1], scores[2]} do
          {p1, p2} when p1 == p2 -> nil
          {p1, p2} when p1 > p2 -> 1
          {p1, p2} when p1 < p2 -> 2
        end

      %{game | winner: winner}
    else
      game
    end
  end

  def complete_turn(game) do
    game = set_robots_at_turn(game)
    update_in(game.turn, &(&1 + 1))
  end

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

  def apply_effects_to_robots(robots, effects) when is_list(robots),
    do: Enum.reduce(effects, robots, &apply_effect_to_robots(&2, &1))

  def apply_effect_to_robots(robots, effect) do
    case effect do
      move_effect(robot_id, x, y) ->
        Enum.map(robots, fn
          %{id: ^robot_id} = robot -> put_in(robot.location, [x, y])
          robot -> robot
        end)

      damage_effect(robot_id, amount) ->
        Enum.map(robots, fn
          %{id: ^robot_id, hp: hp} = robot -> %{robot | hp: hp - amount}
          robot -> robot
        end)

      guard_effect(_robot_id) ->
        robots

      create_robot_effect(robot_id, player_id, hp, x, y) ->
        [%{player_id: player_id, location: [x, y], id: robot_id, hp: hp} | robots]

      remove_robot_effect(robot_id) ->
        Enum.reject(robots, fn robot -> robot.id == robot_id end)
    end
  end

  def new(opts \\ []) do
    settings =
      case opts[:settings] do
        nil -> %Settings{}
        %Settings{} = settings -> settings
        %{} = settings -> Map.merge(%Settings{}, settings)
      end
      |> Map.take([
        :spawn_every,
        :spawn_per_player,
        :robot_hp,
        :max_turns,
        :attack_damage,
        :collision_damage,
        :suicide_damage,
        :terrain,
        :spawn_enabled
      ])

    opts = Enum.into(opts, %{})
    opts = Map.put_new(opts, :id, Ecto.UUID.generate())
    opts = Map.drop(opts, [:settings])
    opts = Map.merge(opts, settings)

    %__MODULE__{}
    |> Map.merge(opts)
  end

  def over?(%__MODULE__{} = game), do: game.winner || game.turn >= game.max_turns

  def score(%__MODULE__{} = game), do: score_at_turn(game, game.turn)

  def score_at_turn(%__MODULE__{} = game, turn) when is_integer(turn) and turn >= 0 do
    robot_score =
      robots_at_turn(game, turn)
      |> Enum.frequencies_by(fn robot -> robot.player_id end)

    Map.merge(%{1 => 0, 2 => 0}, robot_score)
  end

  def dimensions(game), do: Settings.Terrain.dimensions(game.terrain)

  def spawns(game), do: Settings.Terrain.spawn(game.terrain)

  def robots(game), do: robots_at_turn(game, game.turn)

  def spawning_round?(game),
    do: game.spawn_enabled && rem(game.turn, game.spawn_every) == 0

  def get_robot(%__MODULE__{} = game, id), do: get_robot(robots(game), id)

  def get_robot(robots, id) when is_list(robots),
    do: Enum.find(robots, fn robot -> robot.id == id end)

  def get_robot_at_location(%__MODULE__{} = game, location),
    do: get_robot_at_location(robots(game), location)

  def get_robot_at_location(robots, location) when is_list(robots),
    do: Enum.find(robots, fn robot -> robot.location == location end)

  def available_adjacent_locations(%{terrain: terrain}, location) do
    location
    |> adjacent_locations
    |> Enum.filter(&(Terrain.at_location(terrain, &1) in [:spawn, :normal]))
  end

  def adjacent_locations([row, col]) do
    [
      [row + 1, col],
      [row - 1, col],
      [row, col + 1],
      [row, col - 1]
    ]
    |> Enum.filter(fn [row, col] -> row >= 0 && col >= 0 end)
  end

  def guarded_attack_damage(game), do: Integer.floor_div(attack_damage(game), 2)
  def attack_damage(game), do: DamageModifier.calc_damage(game.attack_damage)

  def guarded_suicide_damage(game), do: Integer.floor_div(suicide_damage(game), 2)
  def suicide_damage(game), do: DamageModifier.calc_damage(game.suicide_damage)

  def guarded_collision_damage(_game), do: 0
  def collision_damage(game), do: DamageModifier.calc_damage(game.collision_damage)

  def commands_requests(game) do
    request = %{robots: robots(game), turn: game.turn}
    Map.new([1, 2], fn player -> {player, request} end)
  end

  def settings(game) do
    base_settings =
      Map.take(game, [
        :spawn_every,
        :spawn_per_player,
        :robot_hp,
        :max_turns,
        :attack_damage,
        :collision_damage
      ])

    terrain = Base.encode64(game.terrain)
    Map.put(base_settings, :terrain_base64, terrain)
  end

  def events_for_turn(game, turn) do
    game.events
    |> Enum.filter(fn event -> event.turn == turn end)
  end

  def effects_for_turn(game, turn) do
    events_for_turn(game, turn)
    |> Enum.sort_by(fn event -> event.seq_num end)
    |> Enum.flat_map(fn event -> event.effects end)
  end

  def robots_at_turn(%__MODULE__{} = game, turn) when is_integer(turn) and turn >= 0 do
    game.robots_at_end_of_turn[turn - 1]
    |> apply_effects_to_robots(effects_for_turn(game, turn))
  end

  def set_robots_at_turn(nil), do: nil

  def set_robots_at_turn(game) do
    Enum.reduce(0..game.turn, game, fn turn, game ->
      update_in(game.robots_at_end_of_turn, &Map.put(&1, turn, robots_at_turn(game, turn)))
    end)
  end
end

defimpl BattleBoxGame, for: BattleBox.Games.RobotGame do
  alias BattleBox.Games.RobotGame
  def initialize(game), do: RobotGame.set_robots_at_turn(game)
  def disqualify(game, player), do: RobotGame.disqualify(game, player)
  def over?(game), do: RobotGame.over?(game)
  def settings(game), do: RobotGame.settings(game)
  def commands_requests(game), do: RobotGame.commands_requests(game)
  def calculate_turn(game, commands), do: RobotGame.Logic.calculate_turn(game, commands)
  def score(game), do: RobotGame.score(game)
  def winner(game), do: game.winner
end
