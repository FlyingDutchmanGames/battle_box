defmodule BattleBox.MatchMaker.MatchMakerLogic do
  alias BattleBox.Games.RobotGame.Game

  def make_matches(enqueued_players, _lobby) do
    enqueued_players
    |> Enum.chunk_every(2)
    |> Enum.filter(fn chunk -> length(chunk) == 2 end)
    |> Enum.map(fn
      [player_1, player_2] ->
        %{
          game:
            Game.new(
              player_1: player_1.player_id,
              player_2: player_2.player_id,
              persistent?: false
            ),
          player_1: player_1.pid,
          player_2: player_2.pid
        }
    end)
  end
end
