defmodule BattleBox.Games.RobotGame.Settings.Terrain.Helpers do
  def sigil_t(map, _modifiers) do
    graphs =
      map
      |> String.split("\n")
      |> Enum.map(&String.graphemes/1)
      |> Enum.reject(fn x -> x == [] end)
      |> Enum.map(&Enum.reject(&1, fn grapheme -> String.trim(grapheme) == "" end))

    rows = length(graphs)
    cols = graphs |> Enum.map(&length/1) |> Enum.max(fn -> 0 end)

    header = <<rows::8, cols::8>>

    terrain_data =
      graphs
      |> List.flatten()
      |> Enum.map(&String.to_integer/1)
      |> Enum.map(&<<&1::8>>)

    [header, terrain_data]
    |> IO.iodata_to_binary()
  end
end
