defmodule BattleBox.Games.Marooned.Logic do
  def calculate_turn(game, _commands) do
    # player = game.next_player
    # command = Map.fetch!(commands, player)
    # move_to = command["to"] || Enum.random(available_moves(game, player))

    update_next_player(game)
  end

  defp player_locations(game, turn) do
  end

  defp blocked_off_spaces(game, turn), do: for(%{removed_location: loc} <- game.events, do: loc)

  defp validate_to(game, command_to) do
  end

  defp validate_removal(game, command_removal) do
  end

  defp update_next_player(game) do
    update_in(game.next_player, fn player ->
      %{1 => 2, 2 => 1}[player]
    end)
  end
end
