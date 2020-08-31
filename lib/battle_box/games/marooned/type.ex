defmodule BattleBox.Games.Marooned.Types do
  defmodule BinaryRepr do
    defmacro __using__(_opts) do
      quote do
        use Ecto.Type
        def type, do: :binary

        @version 1
        @turn_size 16
        @player_id_size 8
        @location_size 8
      end
    end
  end

  defmodule Location do
    use BinaryRepr

    defmacrop location(x, y) do
      quote do: <<unquote(x)::@location_size, unquote(y)::@location_size>>
    end

    def cast([_x, _y] = loc), do: {:ok, loc}
    def dump([x, y]), do: {:ok, location(x, y)}
    def load(location(x, y)), do: {:ok, [x, y]}
  end

  defmodule Event do
    use BinaryRepr

    defmacrop event(turn, player, removed_x, removed_y, to_x, to_y) do
      quote do
        <<
          @version,
          unquote(turn)::@turn_size,
          unquote(player)::@player_id_size,
          unquote(removed_x)::@location_size,
          unquote(removed_y)::@location_size,
          unquote(to_x)::@location_size,
          unquote(to_y)::@location_size
        >>
      end
    end

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
      do: {:ok, %{player: player, removed_location: [removed_x, removed_y], to: [to_x, to_y]}}
  end
end
