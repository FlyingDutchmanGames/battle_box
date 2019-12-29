defmodule BattleBox.Games.RobotGame.Game do
  alias BattleBox.Repo
  alias BattleBox.Games.RobotGame.Game.{Terrain, Robot}
  alias __MODULE__.{Event, DamageModifier}
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "robot_games" do
    field :player_1, :binary_id
    field :player_2, :binary_id
    field :spawn_every, :integer, default: 10
    field :spawn_per_player, :integer, default: 5
    field :robot_hp, :integer, default: 50
    field :max_turns, :integer, default: 100
    field :attack_damage, DamageModifier, default: %{min: 8, max: 10}
    field :collision_damage, DamageModifier, default: 5
    field :suicide_damage, DamageModifier, default: 15
    embeds_many :events, Event, on_replace: :delete

    field :terrain, :any, default: Terrain.default(), virtual: true
    field :spawn?, :boolean, default: true, virtual: true
    field :turn, :any, default: 0, virtual: true
    field :unpersisted_events, :any, default: [], virtual: true

    timestamps()
  end

  def changeset(game, params \\ %{}) do
    game
    |> cast(params, [
      :player_1,
      :player_2,
      :spawn_every,
      :spawn_per_player,
      :robot_hp,
      :max_turns,
      :attack_damage,
      :collision_damage,
      :suicide_damage
    ])
    |> cast_embed(:events)
  end

  def get_by_id(id) do
    Repo.one(
      from g in __MODULE__,
        where: g.id == ^id,
        select: g
    )
    |> case do
      nil -> nil
      game -> put_in(game.turn, highes_event_turn_number(game) + 1)
    end
  end

  def persist(game) do
    {:ok, game} =
      game
      |> changeset(%{events: events(game)})
      |> Repo.insert_or_update()

    game = Map.put(game, :unpersisted_events, [])

    {:ok, game}
  end

  def complete_turn(game),
    do: update_in(game.turn, &(&1 + 1))

  def put_events(game, events),
    do: Enum.reduce(events, game, &put_event(&2, &1))

  def put_event(game, event) do
    seq_num = highest_event_seq_num(game) + 1
    event = Map.merge(%{turn: game.turn, seq_num: seq_num}, event)
    update_in(game.unpersisted_events, &[event | &1])
  end

  def apply_effects_to_robots(robots, effects),
    do: Enum.reduce(effects, robots, &apply_effect_to_robots(&2, &1))

  def apply_effect_to_robots(robots, effect) do
    case effect do
      {:move, robot_id, location} ->
        Enum.map(robots, fn
          %{id: ^robot_id} = robot -> put_in(robot.location, location)
          robot -> robot
        end)

      {:damage, robot_id, amount} ->
        Enum.map(robots, fn
          %{id: ^robot_id} = robot -> Robot.apply_damage(robot, amount)
          robot -> robot
        end)

      {:guard, _robot_id} ->
        robots

      {:create_robot, player_id, robot_id, hp, location} ->
        [
          Robot.new(%{
            player_id: player_id,
            location: location,
            id: robot_id,
            hp: hp
          })
          | robots
        ]

      {:remove_robot, robot_id} ->
        Enum.reject(robots, fn robot -> robot.id == robot_id end)
    end
  end

  def new(opts \\ []) do
    opts = Enum.into(opts, %{})

    %__MODULE__{}
    |> Map.merge(opts)
  end

  def score(game, player_id) when player_id in [:player_1, :player_2] do
    game
    |> robots
    |> Enum.filter(fn robot -> robot.player_id == player_id end)
    |> length
  end

  def user(game, :player_1), do: to_string(game.player_1 || "Player 1")
  def user(game, :player_2), do: to_string(game.player_2 || "Player 2")

  def dimensions(game), do: Terrain.dimensions(game.terrain)

  def spawns(game), do: Terrain.spawn(game.terrain)

  def robots(game), do: robots_at_turn(game, game.turn)

  def robots_at_turn(game, turn) do
    unpersisted_events =
      game.unpersisted_events
      |> Enum.reverse()
      |> Enum.filter(fn event -> event.turn <= turn end)
      |> Enum.flat_map(fn event -> event.effects end)

    events =
      game.events
      |> Enum.filter(fn event -> event.turn <= turn end)
      |> Enum.flat_map(fn event -> event.effects end)

    apply_effects_to_robots([], unpersisted_events ++ events)
  end

  def spawning_round?(game),
    do: game.spawn? && rem(game.turn, game.spawn_every) == 0

  def get_robot(%__MODULE__{} = game, id), do: get_robot(robots(game), id)

  def get_robot(robots, id) when is_list(robots),
    do: Enum.find(robots, fn robot -> robot.id == id end)

  def get_robot_at_location(%__MODULE__{} = game, location),
    do: get_robot_at_location(robots(game), location)

  def get_robot_at_location(robots, location) when is_list(robots),
    do: Enum.find(robots, fn robot -> robot.location == location end)

  def available_adjacent_locations(game, location) do
    Enum.filter(adjacent_locations(location), &(game.terrain[&1] in [:normal, :spawn]))
  end

  def adjacent_locations({row, col}),
    do: [
      {row + 1, col},
      {row - 1, col},
      {row, col + 1},
      {row, col - 1}
    ]

  def guarded_attack_damage(game), do: Integer.floor_div(attack_damage(game), 2)
  def attack_damage(game), do: DamageModifier.calc_damage(game.attack_damage)

  def guarded_suicide_damage(game), do: Integer.floor_div(suicide_damage(game), 2)
  def suicide_damage(game), do: DamageModifier.calc_damage(game.suicide_damage)

  def guarded_collision_damage(_game), do: 0
  def collision_damage(game), do: DamageModifier.calc_damage(game.collision_damage)

  defp events(game) do
    (game.events ++ game.unpersisted_events)
    |> Enum.map(fn event -> Map.take(event, [:turn, :seq_num, :cause, :effects]) end)
    |> Enum.sort_by(fn event -> event.seq_num end)
  end

  defp highest_event_seq_num(game) do
    (game.events ++ game.unpersisted_events)
    |> Enum.map(fn event -> event.seq_num end)
    |> Enum.max(fn -> 0 end)
  end

  defp highes_event_turn_number(game) do
    (game.events ++ game.unpersisted_events)
    |> Enum.map(fn event -> event.turn end)
    |> Enum.max(fn -> 0 end)
  end
end
