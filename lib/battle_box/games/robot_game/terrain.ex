defmodule BattleBox.Games.RobotGame.Terrain do
  @tile_definitions %{
    0 => :invalid,
    1 => :normal,
    2 => :spawn,
    3 => :obstacle
  }

  @default [
             [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
             [0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0],
             [0, 0, 0, 0, 0, 2, 2, 1, 1, 1, 1, 1, 2, 2, 0, 0, 0, 0, 0],
             [0, 0, 0, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 0, 0, 0],
             [0, 0, 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
             [0, 0, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0],
             [0, 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
             [0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0],
             [0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
             [0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
             [0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
             [0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0],
             [0, 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
             [0, 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0],
             [0, 0, 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
             [0, 0, 0, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 0, 0, 0],
             [0, 0, 0, 0, 0, 2, 2, 1, 1, 1, 1, 1, 2, 2, 0, 0, 0, 0, 0],
             [0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0],
             [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
           ]
           |> Enum.with_index()
           |> Enum.flat_map(fn {row, row_num} ->
             row
             |> Enum.with_index()
             |> Enum.map(fn {col_val, col_num} ->
               {{row_num, col_num}, @tile_definitions[col_val]}
             end)
           end)
           |> Map.new()

  def default do
    @default
  end

  def spawn(terrain), do: get_type(terrain, :spawn)
  def normal(terrain), do: get_type(terrain, :normal)
  def invalid(terrain), do: get_type(terrain, :invalid)
  def obstacle(terrain), do: get_type(terrain, :obstacle)

  defp get_type(terrain, type), do: for({loc, ^type} <- terrain, do: loc)
end
