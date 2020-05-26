defmodule BattleBox.GameEngine.MatchMaker.MatchMakerLogic do
  alias BattleBox.{Repo, Lobby, Game, GameBot}

  def make_matches([_], _), do: []

  def make_matches(enqueued_players, lobby_id) do
    %Lobby{} = lobby = Repo.get(Lobby, lobby_id)
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
          GameBot.new(player: player, bot: bot)
        end

      player_pid_mapping = Map.new(for {player, %{pid: pid}} <- chunk, do: {player, pid})

      game =
        Game.new(
          lobby: lobby,
          game_bots: game_bots,
          robot_game: RobotGame.new(settings: settings)
        )

      %{game: game, players: player_pid_mapping}
    end)
  end
end
