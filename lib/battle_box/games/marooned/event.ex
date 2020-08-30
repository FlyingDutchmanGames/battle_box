defmodule BattleBox.Games.Marooned.Event do
  use Ecto.Type
  def type, do: :binary

  @player_id_size 8
  @location_size 8

  def cast(%{player: _, removed_location: [_, _], to: [_, _]} = event) do
    {:ok, event}
  end

  def dump(%{player: player, removed_location: [removed_x, removed_y], to: [to_x, to_y]}) do
    event = <<
      player::@player_id_size,
      removed_x::@location_size,
      removed_y::@location_size,
      to_x::@location_size,
      to_y::@location_size
    >>

    {:ok, event}
  end

  def load(<<
        player::@player_id_size,
        removed_x::@location_size,
        removed_y::@location_size,
        to_x::@location_size,
        to_y::@location_size
      >>) do
    {:ok, %{player: player, removed_location: [removed_x, removed_y], to: [to_x, to_y]}}
  end
end
