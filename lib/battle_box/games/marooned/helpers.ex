defmodule BattleBox.Games.Marooned.Helpers do
  alias BattleBox.Games.Marooned

  def sigil_m(game, _modifiers) do
    graphs =
      game
      |> String.downcase()
      |> String.split("\n")
      |> Enum.map(&String.graphemes/1)
      |> Enum.reject(fn x -> x == [] end)
      |> Enum.map(&Enum.reject(&1, fn grapheme -> String.trim(grapheme) == "" end))

    if length(Enum.uniq(for row <- graphs, do: length(row))) != 1,
      do: raise("Invalid Dimensions")

    rows = length(graphs)
    cols = graphs |> Enum.map(&length/1) |> Enum.max(fn -> 0 end)

    graph_with_indexes =
      for {row, y} <- Enum.with_index(Enum.reverse(graphs)),
          {col, x} <- Enum.with_index(row),
          do: {[x, y], col}

    removed = for {loc, "x"} <- graph_with_indexes, do: loc

    player_starting_locations =
      for {loc, player} when player in ~w(1 2) <- graph_with_indexes,
          into: %{},
          do: {String.to_integer(player), loc}

    %Marooned{
      rows: rows,
      cols: cols,
      starting_removed_locations: removed,
      player_starting_locations: player_starting_locations
    }
  end
end
