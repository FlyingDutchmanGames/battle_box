defmodule BattleBox.MatchMaker.MatchMakerLogicTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Lobby, Repo}
  import BattleBox.MatchMaker.MatchMakerLogic
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  @player_1_id Ecto.UUID.generate()
  @player_2_id Ecto.UUID.generate()
  @player_3_id Ecto.UUID.generate()

  setup do
    {:ok, lobby} =
      Lobby.create(%{
        name: "TEST LOBBY",
        game_type: "robot_game",
        user_id: Ecto.UUID.generate()
      })

    %{lobby: lobby}
  end

  test "no players means no matches", %{lobby: lobby} do
    assert [] == make_matches([], lobby.id)
  end

  test "one player means no matches", %{lobby: lobby} do
    player_1_pid = named_proxy(:player_1)
    matches = make_matches([%{player_id: @player_1_id, pid: player_1_pid}], lobby.id)
    assert [] = matches
  end

  test "it will chunk players by twos", %{lobby: lobby} do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    matches =
      make_matches(
        [
          %{player_id: @player_1_id, pid: player_1_pid},
          %{player_id: @player_2_id, pid: player_2_pid}
        ],
        lobby.id
      )

    assert [%{game: game, players: %{"player_1" => ^player_1_pid, "player_2" => ^player_2_pid}}] =
             matches
  end

  test "it will only make one match if there are three in the queue", %{lobby: lobby} do
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
        lobby.id
      )

    assert [%{game: game, players: %{"player_1" => ^player_1_pid, "player_2" => ^player_2_pid}}] =
             matches
  end

  test "the games it makes are persistable", %{lobby: %{id: lobby_id}} do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    [%{game: game}] =
      make_matches(
        [
          %{player_id: @player_1_id, pid: player_1_pid},
          %{player_id: @player_2_id, pid: player_2_pid}
        ],
        lobby_id
      )

    {:ok, game} = BattleBoxGame.persist(game)
    game = Repo.preload(game, game: [:game_bots])
    assert %{lobby_id: lobby_id} = game.game

    assert [
             %{
               player: "player_1",
               bot_id: @player_1_id,
               score: 0
             },
             %{
               player: "player_2",
               bot_id: @player_2_id,
               score: 0
             }
           ] = game.game.game_bots
  end
end
