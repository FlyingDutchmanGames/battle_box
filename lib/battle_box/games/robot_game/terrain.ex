defmodule BattleBox.Games.RobotGame.Terrain do
  alias __MODULE__.Default

  defdelegate default, to: Default

  def spawn(terrain), do: get_type(terrain, :spawn)
  def normal(terrain), do: get_type(terrain, :normal)
  def invalid(terrain), do: get_type(terrain, :invalid)
  def obstacle(terrain), do: get_type(terrain, :obstacle)

  def dimensions(terrain) do
    {row_nums, col_nums} =
      terrain
      |> Map.keys()
      |> Enum.unzip()

    {Enum.max(row_nums), Enum.max(col_nums)}
  end

  defp get_type(terrain, type), do: for({loc, ^type} <- terrain, do: loc)
end
