defmodule BattleBox.GameEngine.MatchMaker.MatchMakerLogic do
  alias BattleBox.{Lobby, Game, GameBot}
  alias BattleBox.Games.RobotGame

  def make_matches([_], _), do: []

  def make_matches(enqueued_players, lobby_id) do
    %Lobby{} = lobby = Lobby.get_by_id(lobby_id)
    settings = Lobby.get_settings(lobby)

    enqueued_players
    |> Enum.chunk_every(2)
    |> Enum.filter(fn chunk -> length(chunk) == 2 end)
    |> Enum.map(fn [player_1, player_2] -> make_match(player_1, player_2, lobby, settings) end)
  end

  defp make_match(player_1, player_2, lobby, settings) do
    game =
      Game.new(
        lobby: lobby,
        game_bots: [
          GameBot.new(player: "player_1", bot_id: player_1.bot_id),
          GameBot.new(player: "player_2", bot_id: player_2.bot_id)
        ],
        robot_game: RobotGame.new(settings: settings)
      )

    %{game: game, players: %{"player_1" => player_1.pid, "player_2" => player_2.pid}}
  end
end
