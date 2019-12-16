defmodule BattleBox.Games.RobotGameTest.Helpers do
  def sigil_g(map, _modifiers) do
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

    graph_with_indexes
    |> Enum.reject(fn {_, val} -> val == "0" end)
    |> Enum.map(fn {location, val} ->
      {val, ""} = Integer.parse(val)

      player_id = if rem(val, 2) == 1, do: :player_1, else: :player_2

      %{move: :test_helper, effects: [{:create_robot, player_id, location, %{id: val}}]}
    end)
  end
end
