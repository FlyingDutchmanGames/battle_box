defmodule BattleBox.GameEngine.MatchMaker.MatchMakerLogic do
  alias BattleBox.{Repo, Lobby, Game, GameBot}

  def make_matches([_], _), do: []

  def make_matches(enqueued_players, lobby_id) do
    %Lobby{} =
      lobby =
      Lobby
      |> Repo.get(lobby_id)
      |> Repo.preload(:user)

    settings = Lobby.get_settings(lobby)
    players = lobby.game_type.players_for_settings(settings)

    enqueued_players
    |> Enum.chunk_every(length(players))
    |> Enum.filter(fn chunk -> length(chunk) == length(players) end)
    |> Enum.map(fn chunk -> Enum.zip(players, chunk) end)
    |> Enum.map(fn chunk ->
      game_bots =
        for {player, %{bot: bot}} <- chunk do
          bot = Repo.preload(bot, :user)
          %GameBot{player: player, bot: bot}
        end

      player_pid_mapping = Map.new(for {player, %{pid: pid}} <- chunk, do: {player, pid})

      game_data =
        struct(lobby.game_type)
        |> Map.merge(Map.take(settings, lobby.game_type.settings_module.shared_fields()))

      game =
        %Game{
          id: Ecto.UUID.generate(),
          lobby: lobby,
          lobby_id: lobby.id,
          game_type: lobby.game_type,
          game_bots: game_bots
        }
        |> Map.put(lobby.game_type.name, game_data)

      %{game: game, players: player_pid_mapping}
    end)
  end
end
