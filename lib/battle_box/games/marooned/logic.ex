defmodule BattleBox.Games.Marooned.Logic do
  alias BattleBox.Game.Error.Timeout

  alias BattleBox.Games.Marooned.Error.{
    CannotMoveIntoOpponent,
    CannotMoveIntoRemovedSquare,
    CannotMoveOffBoard,
    CannotMoveToNonAdjacentSquare,
    CannotMoveToSquareYouAlreadyOccupy,
    CannotRemoveASquareAlreadyRemoved,
    CannotRemoveASquareOutsideTheBoard,
    CannotRemoveSameSquareAsMoveTo,
    CannotRemoveSquareAPlayerIsOn,
    InvalidInputFormat
  }

  import BattleBox.Utilities.Grid, only: [manhattan_distance: 2]

  def calculate_turn(game, commands) do
    {command, input_error} = validate_command(commands[game.next_player])
    {remove, remove_error} = validate_remove(game, game.next_player, command["remove"])
    {to, to_error} = validate_to(game, game.next_player, command["to"])

    event = %{turn: game.turn, player: game.next_player, removed_location: remove, to: to}

    debug = %{
      game.next_player => Enum.reject([input_error, remove_error, to_error], &is_nil/1)
    }

    game = update_in(game.events, &[event | &1])
    game = update_in(game.turn, &(&1 + 1))
    game = update_in(game.next_player, &opponent/1)

    %{game: game, debug: debug, info: %{}}
  end

  def winner(game) do
    game.winner

    cond do
      game.winner -> game.winner
      over?(game) -> opponent(game.next_player)
      true -> nil
    end
  end

  def over?(game) do
    case available_adjacent_locations_for_player(game, game.next_player) do
      [] -> true
      [only_option] -> [only_option] == available_to_be_removed(game)
      [_opt1, _opt2 | _rest] -> false
    end
  end

  def score(game, turn \\ nil) do
    turn = turn || game.turn

    for {player, _} <- player_positions(game, turn),
        into: %{},
        do: {player, length(available_adjacent_locations_for_player(game, player, turn))}
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

    Map.merge(player_starting_locations(game), recent_positions)
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

    for x <- 0..(game.cols - 1),
        y <- 0..(game.rows - 1),
        [x, y] not in removed,
        [x, y] not in occupied,
        do: [x, y]
  end

  def available_adjacent_locations_for_player(game, player, turn \\ nil) do
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

  def opponent(player), do: %{1 => 2, 2 => 1}[player]

  defp adjacent([x, y]) do
    for(
      offset_x <- [-1, 0, 1],
      offset_y <- [-1, 0, 1],
      do: [offset_x + x, offset_y + y]
    ) -- [[x, y]]
  end

  defp player_starting_locations(game) do
    if game.player_starting_locations do
      game.player_starting_locations
    else
      x = div(game.cols, 2)
      %{1 => [x, 0], 2 => [x, game.rows - 1]}
    end
  end

  defp validate_command(%{"to" => [a, b], "remove" => [c, d]} = command) do
    with {:integers?, true} <- {:integers?, Enum.all?([a, b, c, d], &is_integer/1)},
         {:same_space?, false} <- {:same_space?, [a, b] == [c, d]} do
      {command, nil}
    else
      {:integers?, false} -> {command, %InvalidInputFormat{input: command}}
      {:same_space?, true} -> {command, %CannotRemoveSameSquareAsMoveTo{target: [a, b]}}
    end
  end

  defp validate_command(:timeout), do: {%{}, %Timeout{}}

  defp validate_command(command) when is_map(command),
    do: {command, %InvalidInputFormat{input: command}}

  defp validate_command(other), do: {%{}, %InvalidInputFormat{input: other}}

  defp validate_remove(game, player, nil), do: {random_removal_space(game, player), nil}

  defp validate_remove(game, player, [x, y]) when is_integer(x) and is_integer(y) do
    with {:taken?, false} <- {:taken?, [x, y] in Map.values(player_positions(game))},
         {:already_removed?, false} <- {:already_removed?, [x, y] in removed_locations(game)},
         {:in_bounds?, true} <- {:in_bounds?, 0 <= x && x < game.cols && 0 <= y && y < game.rows} do
      {[x, y], nil}
    else
      {:taken?, true} ->
        {random_removal_space(game, player), %CannotRemoveSquareAPlayerIsOn{target: [x, y]}}

      {:already_removed?, true} ->
        {random_removal_space(game, player), %CannotRemoveASquareAlreadyRemoved{target: [x, y]}}

      {:in_bounds?, false} ->
        {random_removal_space(game, player), %CannotRemoveASquareOutsideTheBoard{target: [x, y]}}
    end
  end

  defp validate_remove(game, player, _invalid_type), do: {random_removal_space(game, player), nil}

  defp validate_to(game, player, nil), do: {random_to_space(game, player), nil}

  defp validate_to(game, player, [x, y]) when is_integer(x) and is_integer(y) do
    %{^player => current_position} = player_positions = player_positions(game)

    with {:is_cur_loc?, false} <- {:is_cur_loc?, [x, y] == current_position},
         {:in_bounds?, true} <- {:in_bounds?, 0 <= x && x < game.cols && 0 <= y && y < game.rows},
         {:taken?, false} <- {:taken?, [x, y] in Map.values(player_positions)},
         {:already_removed?, false} <- {:already_removed?, [x, y] in removed_locations(game)},
         {:adjacent?, true} <- {:adjacent?, [x, y] in adjacent(current_position)} do
      {[x, y], nil}
    else
      {:is_cur_loc?, true} ->
        {random_to_space(game, player), %CannotMoveToSquareYouAlreadyOccupy{target: [x, y]}}

      {:taken?, true} ->
        {random_to_space(game, player), %CannotMoveIntoOpponent{target: [x, y]}}

      {:already_removed?, true} ->
        {random_to_space(game, player), %CannotMoveIntoRemovedSquare{target: [x, y]}}

      {:in_bounds?, false} ->
        {random_to_space(game, player), %CannotMoveOffBoard{target: [x, y]}}

      {:adjacent?, false} ->
        {random_to_space(game, player), %CannotMoveToNonAdjacentSquare{target: [x, y]}}
    end
  end

  defp validate_to(game, player, _invalid_type), do: {random_to_space(game, player), nil}

  defp random_removal_space(game, player) do
    enemy_adjacent_opportunities = available_adjacent_locations_for_player(game, opponent(player))

    Enum.min_by(enemy_adjacent_opportunities, &manhattan_distance(&1, [0, 0]), fn ->
      game
      |> available_to_be_removed()
      |> Enum.random()
    end)
  end

  defp random_to_space(game, player) do
    available_adjacent_locations_for_player(game, player)
    |> Enum.max_by(fn location ->
      Enum.sum(
        for {some_player, position} when some_player != player <- player_positions(game),
            do: manhattan_distance(position, location)
      )
    end)
  end
end
