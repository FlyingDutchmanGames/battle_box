defmodule BattleBox.Games.RobotGame.Event do
  use Ecto.Schema
  import Ecto.Changeset

  defmodule Cause do
    use Ecto.Type
    def type, do: :map

    def cast(cause) do
      case cause do
        "spawn" ->
          {:ok, "spawn"}

        "death" ->
          {:ok, "death"}

        %{"type" => type, "robot_id" => _robot_id, "target" => [x, y]}
        when type in ["move", "attack"] and is_integer(x) and is_integer(y) ->
          {:ok, cause}

        %{"type" => type, "robot_id" => _robot_id} when type in ["suicide", "guard", "noop"] ->
          {:ok, cause}
      end
    end

    def load(cause), do: cast(cause)

    def dump(cause), do: {:ok, cause}
  end

  defmodule Effect do
    use Ecto.Type
    def type, do: :map

    def cast(effect) do
      case effect do
        ["move", _robot_id, [_x, _y]] -> {:ok, effect}
        ["damage", _robot_id, _amount] -> {:ok, effect}
        ["guard", _robot_id] -> {:ok, effect}
        ["remove_robot", _robot_id] -> {:ok, effect}
        ["create_robot", _player_id, _robot_id, _hp, [_x, _y]] -> {:ok, effect}
        _ -> :error
      end
    end

    def load(effect), do: cast(effect)

    def dump(effect), do: {:ok, effect}
  end

  @primary_key false

  schema "moves" do
    field :turn, :integer
    field :seq_num, :integer
    field :cause, Cause
    field :effects, {:array, Effect}
  end

  def changeset(move, params) do
    move
    |> cast(params, [:turn, :seq_num, :cause, :effects])
    |> validate_required([:turn, :seq_num, :cause, :effects])
  end
end
