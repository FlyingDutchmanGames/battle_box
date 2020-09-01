defmodule BattleBox.Games.Marooned.Logic do
  import BattleBox.Utilities.Grid, only: [manhattan_distance: 2]

  def calculate_turn(game, commands) do
    available_to_move_to = available_adjacent_locations(game, game.next_player)
    available_to_be_removed = available_to_be_removed(game)

    to =
      if commands["to"] in available_to_move_to do
        commands["to"]
      else
        Enum.max_by(available_to_move_to, fn location ->
          Enum.sum(
            for {player, position} <- player_positions(game),
                player != game.next_player,
                do: manhattan_distance(position, location)
          )
        end)
      end

    remove =
      if commands["remove"] in available_to_be_removed do
        commands["remove"]
      else
        enemy_adjacent_opportunities =
          available_adjacent_locations(game, opponent(game.next_player))

        Enum.min_by(enemy_adjacent_opportunities, &manhattan_distance(&1, [0, 0]))
      end

    event = %{turn: game.turn, player: game.next_player, removed_location: remove, to: to}

    game = update_in(game.events, &[event | &1])
    game = update_in(game.turn, &(&1 + 1))
    update_next_player(game)
  end

  def player_positions(game, turn \\ nil) do
    turn = turn || game.turn

    recent_positions =
      game.events
      |> Enum.filter(&(&1.turn < turn))
      |> Enum.group_by(& &1.player)
      |> Map.new(fn {player, events} ->
        %{to: location} = Enum.max_by(events, & &1.turn)
        {player, location}
      end)

    Map.merge(game.player_starting_locations, recent_positions)
  end

  def removed_locations(game, turn \\ nil) do
    events =
      if turn,
        do: Enum.filter(game.events, &(&1.turn <= turn)),
        else: game.events

    for(%{removed_location: location} <- events, do: location) ++ game.starting_removed_locations
  end

  def available_to_be_removed(game, turn \\ nil) do
    turn = turn || game.turn

    removed = removed_locations(game, turn)
    occupied = Map.values(player_positions(game, turn))

    for row <- 0..(game.rows - 1),
        col <- 0..(game.cols - 1),
        [row, col] not in removed,
        [row, col] not in occupied,
        do: [row, col]
  end

  def available_adjacent_locations(game, player, turn \\ nil) do
    turn = turn || game.turn

    %{^player => current_position} = player_positions = player_positions(game, turn)

    taken = Map.values(player_positions)
    removed = removed_locations(game, turn)

    for [x, y] <- adjacent(current_position),
        [x, y] not in taken,
        [x, y] not in removed,
        0 <= x && x < game.cols,
        0 <= y && y < game.rows,
        do: [x, y]
  end

  defp adjacent([x, y]) do
    for(
      offset_x <- [-1, 0, 1],
      offset_y <- [-1, 0, 1],
      do: [offset_x + x, offset_y + y]
    ) -- [[x, y]]
  end

  defp update_next_player(game), do: update_in(game.next_player, &opponent/1)

  defp opponent(player), do: %{1 => 2, 2 => 1}[player]
end
