defmodule BattleBox.MatchMakerServerTest do
  use ExUnit.Case, async: true
  alias BattleBox.{GameEngine, MatchMaker, MatchMakerServer}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  @player_1_id Ecto.UUID.generate()
  @player_2_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  test "you can start it", names do
    assert names.matchmaker_server
           |> Process.whereis()
           |> Process.alive?()
  end

  test "it will match you up with someone", names do
    lobby_id = Ecto.UUID.generate()
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    :ok = MatchMaker.join_queue(names.matchmaker, lobby_id, @player_1_id, player_1_pid)
    :ok = MatchMaker.join_queue(names.matchmaker, lobby_id, @player_2_id, player_2_pid)
    :ok = MatchMakerServer.force_matchmake(names.matchmaker_server)

    assert_receive {:player_1,
                    {:game_request,
                     %{game_id: game_id, game_server: game_server, settings: settings}}}

    assert_receive {:player_2,
                    {:game_request,
                     %{game_id: ^game_id, game_server: ^game_server, settings: ^settings}}}
  end

  test "it will not match up two players in different lobbies", names do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    :ok =
      MatchMaker.join_queue(names.matchmaker, Ecto.UUID.generate(), @player_1_id, player_1_pid)

    :ok =
      MatchMaker.join_queue(names.matchmaker, Ecto.UUID.generate(), @player_2_id, player_2_pid)

    :ok = MatchMakerServer.force_matchmake(names.matchmaker_server)

    refute_receive {_, {:game_request, _}}
  end
end
