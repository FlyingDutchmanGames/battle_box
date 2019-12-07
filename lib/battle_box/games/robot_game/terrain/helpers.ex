defmodule BattleBox.Games.RobotGame.Terrain.Helpers do
  def sigil_t(map, _modifiers) do
    graphs =
      map
      |> String.split("\n")
      |> Enum.map(&String.graphemes/1)
      |> Enum.reject(fn x -> x == [] end)
      |> Enum.map(&Enum.reject(&1, fn grapheme -> String.trim(grapheme) == "" end))

    graph_with_indexes =
      for {row, row_num} <- Enum.with_index(graphs),
          {col, col_num} <- Enum.with_index(row),
          do: {{row_num, col_num}, col}

    Map.new(graph_with_indexes, fn {loc, val} -> {loc, terrain_val(val)} end)
  end

  defp terrain_val(val) do
    case val do
      "0" -> :inaccessible
      "1" -> :normal
      "2" -> :spawn
      "3" -> :obstacle
      _ -> :normal
    end
  end
end
