defmodule BattleBox.Games.Marooned.Event do
  use Ecto.Type
  def type, do: :binary

  @turn_size 16
  @player_id_size 8
  @location_size 8

  defmacrop event(turn, player, removed_x, removed_y, to_x, to_y) do
    quote do
      <<
        unquote(turn)::unquote(@turn_size),
        unquote(player)::unquote(@player_id_size),
        unquote(removed_x)::unquote(@location_size),
        unquote(removed_y)::unquote(@location_size),
        unquote(to_x)::unquote(@location_size),
        unquote(to_y)::unquote(@location_size)
      >>
    end
  end

  def cast(%{turn: _, player: _, removed_location: [_, _], to: [_, _]} = event) do
    {:ok, event}
  end

  def dump(%{
        turn: turn,
        player: player,
        removed_location: [removed_x, removed_y],
        to: [to_x, to_y]
      }) do
    {:ok, event(turn, player, removed_x, removed_y, to_x, to_y)}
  end

  def load(event(turn, player, removed_x, removed_y, to_x, to_y)) do
    {:ok, %{player: player, removed_location: [removed_x, removed_y], to: [to_x, to_y]}}
  end
end
