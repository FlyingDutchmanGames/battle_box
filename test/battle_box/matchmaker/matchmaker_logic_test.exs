defmodule BattleBox.MatchMaker.MatchMakerLogicTest do
  use ExUnit.Case, async: true
  import BattleBox.MatchMaker.MatchMakerLogic
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  @player_1_id Ecto.UUID.generate()
  @player_2_id Ecto.UUID.generate()
  @player_3_id Ecto.UUID.generate()

  test "no players means no matches" do
    assert [] == make_matches([], "lobby")
  end

  test "one player means no matches" do
    player_1_pid = named_proxy(:player_1)
    matches = make_matches([%{player_id: @player_1_id, pid: player_1_pid}], "lobby")
    assert [] = matches
  end

  test "it will chunk players by twos" do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    matches =
      make_matches(
        [
          %{player_id: @player_1_id, pid: player_1_pid},
          %{player_id: @player_2_id, pid: player_2_pid}
        ],
        "lobby"
      )

    assert [%{game: game, player_1: ^player_1_pid, player_2: ^player_2_pid}] = matches
    assert game.player_1 == @player_1_id
    assert game.player_2 == @player_2_id
  end

  test "it will only make one match if there are three in the queue" do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)
    player_3_pid = named_proxy(:player_3)

    matches =
      make_matches(
        [
          %{player_id: @player_1_id, pid: player_1_pid},
          %{player_id: @player_2_id, pid: player_2_pid},
          %{player_id: @player_3_id, pid: player_3_pid}
        ],
        "lobby"
      )

    assert [%{game: game, player_1: ^player_1_pid, player_2: ^player_2_pid}] = matches
    assert game.player_1 == @player_1_id
    assert game.player_2 == @player_2_id
  end
end
