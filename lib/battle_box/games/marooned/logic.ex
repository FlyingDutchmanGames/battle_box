defmodule BattleBox.Games.Marooned.Logic do
  def calculate_turn(game, commands) do
    command = Map.fetch!(commands, game.next_player)

    update_next_player(game)
  end

  defp update_next_player(game) do
    update_in(game.next_player, fn player ->
      %{1 => 2, 2 => 1}[player]
    end)
  end
end
