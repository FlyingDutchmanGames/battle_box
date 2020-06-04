defmodule BattleBox.Games.RobotGame.Settings.Terrain do
  alias __MODULE__.Default

  defdelegate default, to: Default

  def validate(terrain) do
    with {:size_header, <<rows::8, cols::8, data::binary>>} <- {:size_header, terrain},
         {:size, rows, cols} when rows in 1..40 and cols in 1..40 <- {:size, rows, cols},
         {:data_amount_correct, true} <- {:data_amount_correct, rows * cols == byte_size(data)},
         {:illegal_bytes, []} <- {:illegal_bytes, for(<<i <- data>>, i > 3, do: i)} do
      :ok
    else
      {:size_header, _} ->
        {:error, "Illegal Size Header"}

      {:size, _rows, _cols} ->
        {:error, "Rows and cols must be between 1 and 40"}

      {:data_amount_correct, false} ->
        {:error, "Terrain data byte size must equal rows * cols"}

      {:illegal_bytes, bytes} ->
        {:error, "Terrain data must have bytes less than 3, but found bytes #{inspect(bytes)}"}
    end
  end

  def rows(<<rows::8, _cols::8, _::binary>>), do: rows
  def cols(<<_rows::8, cols::8, _::binary>>), do: cols

  def resize(<<_current_rows::8, _current_cols::8, data::binary>>, desired_rows, desired_cols) do
    # 🤷
    amount_of_bytes_needed = desired_rows * desired_cols
    replicas = Integer.floor_div(amount_of_bytes_needed, byte_size(data))

    <<new_data::binary-size(amount_of_bytes_needed), _rest::binary>> =
      :binary.copy(data, replicas + 1)

    <<desired_rows::8, desired_cols::8, new_data::binary>>
  end

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

  def set_at_location(terrain, [row, col], type) do
    <<rows::8, cols::8, data::binary>> = terrain
    offset = row * cols + col
    <<prefix::binary-size(offset), _replace::8, suffix::binary>> = data
    <<rows::8, cols::8, prefix::binary, type_to_int(type)::8, suffix::binary>>
  end

  def inaccessible(terrain), do: get_type(terrain, 0)
  def normal(terrain), do: get_type(terrain, 1)
  def spawn(terrain), do: get_type(terrain, 2)
  def obstacle(terrain), do: get_type(terrain, 3)

  def dimensions2(<<rows::8, cols::8, _::binary>>), do: %{rows: rows, cols: cols}

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

  defp type_to_int(type) do
    case type do
      :inaccessible -> 0
      :normal -> 1
      :spawn -> 2
      :obstacle -> 3
    end
  end
end
