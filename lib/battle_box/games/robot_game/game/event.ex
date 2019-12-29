defmodule BattleBox.Games.RobotGame.Game.Event do
  use Ecto.Schema
  import Ecto.Changeset

  defmodule Cause do
    use Ecto.Type
    def type, do: :map

    def cast(cause) do
      case cause do
        spawn when spawn in [:spawn, "spawn"] ->
          {:ok, :spawn}

        %{type: _, robot_id: _} = cause ->
          {:ok, cause}

        %{"type" => type, "robot_id" => robot_id, "target" => [x, y]} ->
          {:ok, %{type: stea(type), robot_id: robot_id, target: {x, y}}}

        %{"type" => type, "robot_id" => robot_id} ->
          {:ok, %{robot_id: robot_id, type: stea(type)}}
      end
    end

    def load(cause), do: cast(cause)

    def dump(cause), do: {:ok, cause}

    defp stea(string), do: String.to_existing_atom(string)
  end

  defmodule Effect do
    use Ecto.Type
    def type, do: :map

    def cast(effect) do
      case effect do
        {:move, _, _} ->
          {:ok, effect}

        ["move", robot_id, [x, y]] ->
          {:ok, {:move, robot_id, {x, y}}}

        {:damage, _, _} ->
          {:ok, effect}

        ["damage", robot_id, amount] ->
          {:ok, {:damage, robot_id, amount}}

        {:guard, _} ->
          {:ok, effect}

        ["guard", robot_id] ->
          {:ok, {:guard, robot_id}}

        {:remove_robot, _} ->
          {:ok, effect}

        ["remove_robot", robot_id] ->
          {:ok, {:remove_robot, robot_id}}

        {:create_robot, _, _, _, _} ->
          {:ok, effect}

        ["create_robot", player_id, robot_id, hp, [x, y]] ->
          {:ok, {:create_robot, stea(player_id), robot_id, hp, {x, y}}}
      end
    end

    def load(effect), do: cast(effect)

    def dump(effect), do: {:ok, effect}

    defp stea(string), do: String.to_existing_atom(string)
  end

  @primary_key false

  schema "moves" do
    field :turn_num, :integer, required: true
    field :seq_num, :integer
    field :cause, Cause
    field :effects, {:array, Effect}
  end

  def changeset(move, params) do
    move
    |> cast(params, [:turn_num, :seq_num, :cause, :effects])
  end
end
