defmodule BattleBox.Games.RobotGame.Game do
  alias BattleBox.Games.RobotGame.{Terrain, Robot}

  defstruct terrain: Terrain.default(),
            robots: [],
            turn: 0,
            player_1: nil,
            player_2: nil,
            spawn?: true,
            spawn_every: 10,
            spawn_per_player: 5,
            robot_hp: 50,
            attack_damage: %{min: 8, max: 10},
            collision_damage: 5,
            suicide_damage: 15,
            max_turns: 100,
            event_log: []

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

  defp log(game, event) do
    event = Map.put(event, :turn, game.turn)
    update_in(game.event_log, fn log -> [event | log] end)
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

  def apply_damage_to_robot(game, id, damage) do
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
end
