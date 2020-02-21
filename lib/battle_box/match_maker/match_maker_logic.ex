defmodule BattleBox.MatchMaker.MatchMakerLogic do
  alias BattleBox.{Lobby, BattleBoxGame}
  alias BattleBox.Games.RobotGame.Settings

  def make_matches(enqueued_players, lobby_id) do
    %Lobby{} = lobby = Lobby.get_by_id(lobby_id)

    enqueued_players
    |> Enum.chunk_every(2)
    |> Enum.filter(fn chunk -> length(chunk) == 2 end)
    |> Enum.map(fn [player_1, player_2] -> make_match(player_1, player_2, lobby) end)
  end

  defp make_match(player_1, player_2, lobby) do
    {:ok, bbg} =
      BattleBoxGame.create(%{
        lobby: lobby,
        players: %{
          "player_1" => player_1.player_id,
          "player_2" => player_2.player_id
        }
      })

    game =
      Ecto.build_assoc(bbg, :robot_game, %{
        id: Ecto.UUID.generate(),
        settings: Settings.new(),
        battle_box_game: bbg
      })

    %{game: game, players: %{"player_1" => player_1.pid, "player_2" => player_2.pid}}
  end
end
