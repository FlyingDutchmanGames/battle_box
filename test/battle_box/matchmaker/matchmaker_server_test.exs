defmodule BattleBox.MatchMakerServerTest do
  use ExUnit.Case, async: true
  alias BattleBox.MatchMakerServer
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  @matchmaker_init %{
    game_server_supervisor: RobotGame.GameSupervisor
  }

  test "you can start it" do
    {:ok, pid} = MatchMakerServer.start_link(@matchmaker_init)
    assert Process.alive?(pid)
  end

  test "you can ask to be matchmade" do
    {:ok, pid} = MatchMakerServer.start_link(@matchmaker_init)
    p1 = uuid()
    p2 = uuid()
    :ok = MatchMakerServer.join_matchmaker_queue(p1, named_proxy(:player_1), pid)
    :ok = MatchMakerServer.join_matchmaker_queue(p2, named_proxy(:player_2), pid)

    assert_receive {:player_1,
                    {:game_request,
                     %{game_id: game_id, game_server: game_server, settings: settings}}}

    assert_receive {:player_2,
                    {:game_request,
                     %{game_id: ^game_id, game_server: ^game_server, settings: ^settings}}}
  end

  defp uuid do
    Ecto.UUID.generate()
  end
end
