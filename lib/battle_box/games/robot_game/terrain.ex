defmodule BattleBox.Games.RobotGame.Terrain do
  alias __MODULE__.Default

  defdelegate default, to: Default

  def spawn(terrain), do: get_type(terrain, :spawn)
  def normal(terrain), do: get_type(terrain, :normal)
  def invalid(terrain), do: get_type(terrain, :invalid)
  def obstacle(terrain), do: get_type(terrain, :obstacle)

  defp get_type(terrain, type), do: for({loc, ^type} <- terrain, do: loc)
end
