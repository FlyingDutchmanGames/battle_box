defmodule BattleBox.Games.RobotGame.Game do
  alias BattleBox.Repo
  alias BattleBox.Games.RobotGame.{Terrain, Robot}
  alias __MODULE__.{Turn, DamageModifier}
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
    has_many :turns, Turn

    field :terrain, :any, default: Terrain.default(), virtual: true
    field :spawn?, :boolean, default: true, virtual: true
    field :robots, :any, default: [], virtual: true
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
  end

  def get_by_id(id) do
    query =
      from g in __MODULE__,
        where: g.id == ^id,
        select: g,
        preload: [:turns]

    case Repo.one(query) do
      nil ->
        nil

      game ->
        project_events_into_robots(game)
    end
  end

  def persist(game) do
    {:ok, game} =
      game
      |> changeset
      |> Repo.insert_or_update()

    game.unpersisted_events
    |> Enum.group_by(fn event -> event.turn end)
    |> Enum.each(fn {turn_num, events} ->
      events = Enum.map(events, fn event -> Map.take(event, [:cause, :effects]) end)
      turn = Turn.changeset(%Turn{}, %{turn_number: turn_num, moves: events, game_id: game.id})
      {:ok, _} = Repo.insert(turn)
    end)

    {:ok, get_by_id(game.id)}
  end

  def complete_turn(game) do
    update_in(game.turn, &(&1 + 1))
  end

  def apply_events(game, events), do: Enum.reduce(events, game, &apply_event(&2, &1))

  def apply_event(game, event) do
    game = log(game, event)
    Enum.reduce(event.effects, game, &apply_effect(&2, &1))
  end

  def apply_effect(game, effect) do
    case effect do
      {:move, robot_id, location} ->
        move_robot(game, robot_id, location)

      {:damage, robot_id, amount} ->
        apply_damage_to_robot(game, robot_id, amount)

      {:guard, _robot_id} ->
        game

      {:create_robot, player_id, location} ->
        add_robot(game, player_id, location, %{})

      {:create_robot, player_id, location, opts} ->
        add_robot(game, player_id, location, opts)

      {:remove_robot, robot_id} ->
        remove_robot(game, robot_id)
    end
  end

  def new(opts \\ []) do
    opts = Enum.into(opts, %{})
    Map.merge(%__MODULE__{}, opts)
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

  def robots(game), do: game.robots

  def spawning_round?(game),
    do: game.spawn? && rem(game.turn, game.spawn_every) == 0

  def get_robot(game, id),
    do: Enum.find(game.robots, fn robot -> robot.id == id end)

  def get_robot_at_location(game, location),
    do: Enum.find(game.robots, fn robot -> robot.location == location end)

  defp log(game, event) do
    event = Map.put(event, :turn, game.turn)
    update_in(game.unpersisted_events, fn events -> [event | events] end)
  end

  defp apply_damage_to_robot(game, id, damage) do
    update_in(
      game.robots,
      &Enum.map(&1, fn
        %{id: ^id} = robot -> Robot.apply_damage(robot, damage)
        robot -> robot
      end)
    )
  end

  defp move_robot(game, id, location) do
    update_in(
      game.robots,
      &Enum.map(&1, fn
        %{id: ^id} = robot -> put_in(robot.location, location)
        robot -> robot
      end)
    )
  end

  defp add_robot(game, player_id, location, opts) when player_id in [:player_1, :player_2] do
    opts = Map.merge(opts, %{player_id: player_id, location: location})

    update_in(game.robots, fn robots ->
      [Robot.new(Map.merge(%{hp: game.robot_hp}, opts)) | robots]
    end)
  end

  defp remove_robot(game, id),
    do: update_in(game.robots, &Enum.reject(&1, fn robot -> robot.id == id end))

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
  def attack_damage(game), do: calc_damage(game.attack_damage)

  def guarded_suicide_damage(game), do: Integer.floor_div(suicide_damage(game), 2)
  def suicide_damage(%{suicide_damage: damage}), do: damage

  def guarded_collision_damage(_game), do: 0
  def collision_damage(game), do: calc_damage(game.collision_damage)

  defp calc_damage(damage) do
    case damage do
      %{max: value, min: value} ->
        value

      %{max: max, min: min} ->
        min + :rand.uniform(max - min)

      value when is_integer(value) ->
        value
    end
  end

  defp project_events_into_robots(game) do
    effects =
      game.turns
      |> Enum.sort_by(fn turn -> turn.turn_number end)
      |> Enum.flat_map(fn turn -> turn.moves end)
      |> Enum.flat_map(fn move -> move.effects end)

    Enum.reduce(effects, game, fn effect, game ->
      apply_effect(game, effect)
    end)
  end
end
