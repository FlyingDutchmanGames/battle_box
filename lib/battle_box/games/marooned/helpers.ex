defmodule BattleBox.Games.Marooned.Helpers do
  alias BattleBox.Games.Marooned

  def sigil_m(game, _modifiers) do
    graphs =
      game
      |> String.split("\n")
      |> Enum.map(&String.graphemes/1)
      |> Enum.reject(fn x -> x == [] end)
      |> Enum.map(&Enum.reject(&1, fn grapheme -> String.trim(grapheme) == "" end))

    if length(Enum.uniq(for row <- graphs, do: length(row))) != 1,
      do: raise("Invalid Dimensions")

    rows = length(graphs)
    cols = graphs |> Enum.map(&length/1) |> Enum.max(fn -> 0 end)

    graph_with_indexes =
      for {row, row_num} <- Enum.with_index(Enum.reverse(graphs)),
          {col, col_num} <- Enum.with_index(row),
          do: {[row_num, col_num], col}

    %Marooned{
      rows: rows,
      cols: cols
    }
  end
end
