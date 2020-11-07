defmodule BattleBox.GameEngine.MatchMaker.MatchMakerLogic do
  alias BattleBox.{Arena, Game}

  def make_matches([_], _), do: []

  def make_matches(enqueued_players, arena) do
    players = Arena.players(arena)

    grouper_function =
      case arena do
        %{user_self_play: false} -> & &1.bot.user_id
        %{bot_self_play: false} -> & &1.bot.id
        _ -> fn _ -> :erlang.unique_integer() end
      end

    enqueued_players
    |> match_players(players, grouper_function)
    |> Enum.map(fn match ->
      player_bot_mapping = Map.new(match, fn {player, %{bot: bot}} -> {player, bot} end)
      player_pid_mapping = Map.new(match, fn {player, %{pid: pid}} -> {player, pid} end)
      game = Game.build(arena, player_bot_mapping)
      %{game: game, players: player_pid_mapping}
    end)
  end

  defp match_players(enqueued_players, players, grouper_function) do
    enqueued_players
    |> Enum.group_by(grouper_function)
    |> Enum.map(fn {_key, values} -> values end)
    |> Stream.unfold(fn need_to_be_matched ->
      need_to_be_matched =
        need_to_be_matched
        |> Enum.reject(&(&1 == []))
        |> Enum.shuffle()

      if length(need_to_be_matched) >= length(players) do
        begin = Enum.take(need_to_be_matched, length(players))
        rest = Enum.drop(need_to_be_matched, length(players))

        {selected, begin} =
          begin
          |> Enum.map(&List.pop_at(&1, 0))
          |> Enum.unzip()

        match = Enum.zip(players, selected)
        {match, begin ++ rest}
      end
    end)
    |> Enum.to_list()
  end
end
