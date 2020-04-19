defmodule BattleBox.Games.RobotGame.Settings.Terrain do
  alias __MODULE__.Default

  defdelegate default, to: Default

  def rows(<<rows::8, _cols::8, _::binary>>), do: rows
  def cols(<<_rows::8, cols::8, _::binary>>), do: cols

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

  def inaccessible(terrain), do: get_type(terrain, 0)
  def normal(terrain), do: get_type(terrain, 1)
  def spawn(terrain), do: get_type(terrain, 2)
  def obstacle(terrain), do: get_type(terrain, 3)

  def dimensions(<<rows::8, cols::8, _::binary>>) do
    %{
      row_min: 0,
      row_max: rows - 1,
      col_min: 0,
      col_max: cols - 1
    }
  end

  defp get_type(terrain, type) do
    <<_rows::8, cols::8, terrain_data::binary>> = terrain

    for(<<terrain_val <- terrain_data>>, do: terrain_val)
    |> Enum.with_index()
    |> Enum.filter(fn {terrain_val, _offset} -> terrain_val == type end)
    |> Enum.map(fn {_, offset} ->
      row = Integer.floor_div(offset, cols)
      col = rem(offset, cols)

      [row, col]
    end)
  end
end
