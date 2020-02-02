defmodule BattleBox.MatchMakerTest do
  use ExUnit.Case, async: true
  alias BattleBox.MatchMaker

  @matchmaker_init %{
    game_server_supervisor: RobotGame.GameSupervisor
  }

  test "you can start it" do
    {:ok, pid} = MatchMaker.start_link(@matchmaker_init)
    assert Process.alive?(pid)
  end

  test "you can ask to be matchmade" do
    {:ok, pid} = MatchMaker.start_link(@matchmaker_init)
    p1 = uuid()
    p2 = uuid()
    :ok = MatchMaker.join_matchmaker_queue(p1, self(), pid)
    :ok = MatchMaker.join_matchmaker_queue(p2, self(), pid)
    assert_receive {:game_request, %{}}
    assert_receive {:game_request, %{}}
  end

  defp uuid do
    Ecto.UUID.generate()
  end
end
