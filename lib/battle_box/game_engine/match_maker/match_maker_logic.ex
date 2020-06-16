defmodule BattleBox.GameEngine.MatchMaker.MatchMakerLogic do
  alias BattleBox.{Repo, Arena, Game, GameBot}

  def make_matches([_], _), do: []

  def make_matches(enqueued_players, arena_id) do
    %Arena{} =
      arena =
      Arena
      |> Repo.get(arena_id)
      |> Repo.preload(:user)

    settings = Arena.get_settings(arena)
    players = arena.game_type.players_for_settings(settings)

    grouper_function =
      case arena do
        %{user_self_play: false} -> & &1.bot.user_id
        %{bot_self_play: false} -> & &1.bot.id
        _ -> fn _ -> :erlang.unique_integer() end
      end

    enqueued_players
    |> match_players(players, grouper_function)
    |> Enum.map(fn match ->
      game_bots =
        for {player, %{bot: bot}} <- match do
          bot = Repo.preload(bot, :user)
          %GameBot{player: player, bot: bot}
        end

      player_pid_mapping = Map.new(for {player, %{pid: pid}} <- match, do: {player, pid})

      game_data =
        struct(arena.game_type)
        |> Map.merge(Map.take(settings, arena.game_type.settings_module.shared_fields()))

      game =
        %Game{
          id: Ecto.UUID.generate(),
          arena: arena,
          arena_id: arena.id,
          game_type: arena.game_type,
          game_bots: game_bots
        }
        |> Map.put(arena.game_type.name, game_data)

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
