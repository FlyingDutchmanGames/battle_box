defmodule BattleBox.Games.RobotGame.Settings.Terrain do
  alias __MODULE__.Default

  defdelegate default, to: Default

  def at_location(terrain, [row, col]) do
    <<rows::8, cols::8, data::binary>> = terrain

    on_board? = row >= 0 && col >= 0 && row <= rows - 1 && col <= cols - 1

    if on_board? do
      offset = row * cols + col

      case :binary.at(data, offset) do
        0 -> :inaccessible
        1 -> :normal
        2 -> :spawn
        3 -> :obstacle
      end
    else
      :inaccessible
    end
  end

  def spawn(terrain), do: get_type(terrain, :spawn)
  def normal(terrain), do: get_type(terrain, :normal)
  def invalid(terrain), do: get_type(terrain, :invalid)
  def obstacle(terrain), do: get_type(terrain, :obstacle)

  def dimensions(terrain) when terrain == %{}, do: nil

  def dimensions(terrain) do
    {row_nums, col_nums} =
      terrain
      |> Map.keys()
      |> Enum.map(&List.to_tuple/1)
      |> Enum.unzip()

    %{
      row_min: Enum.min(row_nums),
      row_max: Enum.max(row_nums),
      col_min: Enum.min(col_nums),
      col_max: Enum.max(col_nums)
    }
  end

  defp get_type(terrain, type), do: for({loc, ^type} <- terrain, do: loc)
end
