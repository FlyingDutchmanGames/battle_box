defmodule BattleBox.Games.RobotGame.Game.DamageModifier do
  use Ecto.Type
  def type, do: :map

  def cast(%{min: _, max: _} = modifier), do: {:ok, modifier}
  def cast(damage) when is_integer(damage), do: {:ok, damage}
  def cast(_), do: :error

  def load(%{"min" => min, "max" => max}), do: {:ok, %{min: min, max: max}}
  def load(%{"always" => damage}), do: {:ok, damage}
  def load(_), do: :error

  def dump(%{min: min, max: max}), do: {:ok, %{"min" => min, "max" => max}}
  def dump(damage) when is_integer(damage), do: {:ok, %{"always" => damage}}
  def dump(_), do: :error

  def calc_damage(damage) do
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
