defmodule BattleBox.Games.RobotGame.Game.Move do
  use Ecto.Type
  def type, do: :map

  def cast(%{cause: _, effects: _} = move) do
    {:ok, move}
  end

  def dump(%{cause: _, effects: _} = move) do
    {:ok, as_json(move)}
  end

  def load(%{"cause" => cause, "effects" => effects}) do
    {:ok,
     %{
       cause: decode_cause(cause),
       effects: Enum.map(effects, &decode_effect/1)
     }}
  end

  defp decode_cause(cause) do
    case cause do
      "spawn" ->
        :spawn

      %{"type" => type, "robot_id" => robot_id, "target" => [x, y]} ->
        %{type: String.to_existing_atom(type), robot_id: robot_id, target: {x, y}}

      %{"type" => type, "robot_id" => robot_id} ->
        %{type: String.to_existing_atom(type), robot_id: robot_id}
    end
  end

  defp decode_effect(effect) do
    case effect do
      ["move", robot_id, [x, y]] ->
        {:move, robot_id, {x, y}}

      ["damage", robot_id, amount] ->
        {:damage, robot_id, amount}

      ["guard", robot_id] ->
        {:guard, robot_id}

      ["create_robot", player_id, [x, y]] ->
        {:create_robot, player_id, {x, y}}

      ["create_robot", player_id, [x, y], opts] ->
        {:create_robot, player_id, {x, y}, decode_opts(opts)}

      ["remove_robot", robot_id] ->
        {:remove_robot, robot_id}
    end
  end

  defp decode_opts(opts) do
    Map.new(opts, fn {k, v} -> {String.to_existing_atom(k), v} end)
  end

  defp as_json(item) do
    # I'm so sorry...
    item
    |> Jason.encode!()
    |> Jason.decode!()
  end
end
