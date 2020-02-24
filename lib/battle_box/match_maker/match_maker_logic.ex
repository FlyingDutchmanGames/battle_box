defmodule BattleBox.MatchMaker.MatchMakerLogic do
  alias BattleBox.{Lobby, BattleBoxGame, BattleBoxGameBot}
  alias BattleBox.Games.RobotGame.{Settings, Game}

  def make_matches(enqueued_players, lobby_id) do
    %Lobby{} = lobby = Lobby.get_by_id(lobby_id)

    enqueued_players
    |> Enum.chunk_every(2)
    |> Enum.filter(fn chunk -> length(chunk) == 2 end)
    |> Enum.map(fn [player_1, player_2] -> make_match(player_1, player_2, lobby) end)
  end

  defp make_match(player_1, player_2, lobby) do
    p1_bot = BattleBoxGameBot.new(player: "player_1", bot_id: player_1.player_id)
    p2_bot = BattleBoxGameBot.new(player: "player_2", bot_id: player_2.player_id)
    bbg = BattleBoxGame.new(lobby_id: lobby.id, battle_box_game_bots: [p1_bot, p2_bot])

    game = Game.new(settings: Settings.new(), battle_box_game: bbg)
    %{game: game, players: %{"player_1" => player_1.pid, "player_2" => player_2.pid}}
  end
end
