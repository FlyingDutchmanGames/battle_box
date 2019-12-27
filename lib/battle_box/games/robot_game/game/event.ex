defmodule BattleBox.Games.RobotGame.Game.Event do
  use Ecto.Schema
  import Ecto.Changeset

  defmodule Cause do
    use Ecto.Type
    def type, do: :map

    def cast(:spawn), do: {:ok, :spawn}
    def cast("spawn"), do: {:ok, :spawn}
    def cast(%{type: _, robot_id: _} = cause), do: {:ok, cause}

    def cast(%{"type" => type, "robot_id" => robot_id, "target" => [x, y]}) do
      {:ok, %{type: stea(type), robot_id: robot_id, target: {x, y}}}
    end

    def cast(%{"type" => type, "robot_id" => robot_id}),
      do: {:ok, %{robot_id: robot_id, type: stea(type)}}

    def load("spawn"), do: {:ok, :spawn}

    def load(%{"type" => type, "robot_id" => robot_id, "target" => [x, y]}) do
      {:ok, %{type: stea(type), robot_id: robot_id, target: {x, y}}}
    end

    def load(%{"type" => type, "robot_id" => robot_id}) do
      {:ok, %{type: stea(type), robot_id: robot_id}}
    end

    def dump(cause) do
      {:ok, cause}
    end

    defp stea(string), do: String.to_existing_atom(string)
  end

  defmodule Effect do
    use Ecto.Type
    def type, do: :map

    def cast({:move, _, _} = effect), do: {:ok, effect}
    def cast({:damage, _, _} = effect), do: {:ok, effect}
    def cast({:guard, _} = effect), do: {:ok, effect}
    def cast({:create_robot, _, _, _, _} = effect), do: {:ok, effect}
    def cast({:remove_robot, _} = effect), do: {:ok, effect}

    def cast(["move", robot_id, [x, y]]), do: {:ok, {:move, robot_id, {x, y}}}
    def cast(["damage", robot_id, amount]), do: {:ok, {:damage, robot_id, amount}}
    def cast(["guard", robot_id]), do: {:ok, {:guard, robot_id}}

    def cast(["create_robot", player_id, robot_id, [x, y], opts]),
      do: {:ok, {:create_robot, stea(player_id), robot_id, {x, y}, decode_opts(opts)}}

    def cast(["remove_robot", robot_id]), do: {:ok, {:remove_robot, robot_id}}

    def load(["move", robot_id, [x, y]]), do: {:ok, {:move, robot_id, {x, y}}}
    def load(["damage", robot_id, amount]), do: {:ok, {:damage, robot_id, amount}}
    def load(["guard", robot_id]), do: {:ok, {:guard, robot_id}}

    def load(["create_robot", player_id, [x, y]]),
      do: {:ok, {:create_robot, stea(player_id), {x, y}}}

    def load(["create_robot", player_id, robot_id, [x, y], opts]),
      do: {:ok, {:create_robot, stea(player_id), robot_id, {x, y}, decode_opts(opts)}}

    def load(["remove_robot", robot_id]), do: {:ok, {:remove_robot, robot_id}}

    def dump({:guard, robot_id}), do: {:ok, ["guard", robot_id]}
    def dump({:remove_robot, robot_id}), do: {:ok, ["remove_robot", robot_id]}
    def dump({:move, robot_id, {x, y}}), do: {:ok, ["move", robot_id, [x, y]]}
    def dump({:damage, robot_id, amount}), do: {:ok, ["damage", robot_id, amount]}
    def dump({:create_robot, player_id, {x, y}}), do: {:ok, ["create_robot", player_id, [x, y]]}

    def dump({:create_robot, player_id, robot_id, {x, y}, opts}),
      do: {:ok, ["create_robot", player_id, robot_id, [x, y], opts]}

    defp decode_opts(opts) do
      Map.new(opts, fn {k, v} -> {stea(k), v} end)
    end

    defp stea(string), do: String.to_existing_atom(string)
  end

  @primary_key false

  schema "moves" do
    field :cause, Cause
    field :effects, {:array, Effect}
  end

  def changeset(move, params) do
    move
    |> cast(params, [:cause, :effects])
  end
end
