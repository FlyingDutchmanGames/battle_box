defmodule BattleBox.Games.Marooned.Types do
  # Edit this module with care, as data can be written to the database
  # that still needs to be read

  defmodule BinaryRepr do
    defmacro location(x, y) do
      quote do: <<unquote(x)::8, unquote(y)::8>>
    end

    defmacro player_starting_location(player, x, y) do
      quote do: <<
              unquote(player)::8,
              unquote(x)::8,
              unquote(y)::8
            >>
    end

    defmacro event(turn, player, removed_x, removed_y, to_x, to_y) do
      quote do
        <<
          # version
          1,
          unquote(turn)::16,
          unquote(player)::8,
          unquote(removed_x)::8,
          unquote(removed_y)::8,
          unquote(to_x)::8,
          unquote(to_y)::8
        >>
      end
    end
  end

  defmodule Location do
    import BinaryRepr
    use Ecto.Type
    def type, do: :binary

    def cast([_x, _y] = loc), do: {:ok, loc}
    def dump([x, y]), do: {:ok, location(x, y)}
    def load(location(x, y)), do: {:ok, [x, y]}
  end

  defmodule Event do
    import BinaryRepr
    use Ecto.Type
    def type, do: :binary

    def cast(%{turn: _, player: _, removed_location: [_, _], to: [_, _]} = event),
      do: {:ok, event}

    def dump(%{
          turn: turn,
          player: player,
          removed_location: [removed_x, removed_y],
          to: [to_x, to_y]
        }),
        do: {:ok, event(turn, player, removed_x, removed_y, to_x, to_y)}

    def load(event(turn, player, removed_x, removed_y, to_x, to_y)),
      do:
        {:ok,
         %{turn: turn, player: player, removed_location: [removed_x, removed_y], to: [to_x, to_y]}}
  end

  defmodule PlayerStartingLocations do
    import BinaryRepr
    use Ecto.Type

    def type, do: {:array, :binary}

    def cast(map) when is_map(map), do: {:ok, map}

    def dump(map) do
      {:ok, for({player, [x, y]} <- map, do: player_starting_location(player, x, y))}
    end

    def load(array) do
      {:ok, for(player_starting_location(player, x, y) <- array, into: %{}, do: {player, [x, y]})}
    end
  end
end
