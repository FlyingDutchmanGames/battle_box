defmodule BattleBox.PlayerServerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{GameEngine, MatchMaker, PlayerServer, Repo, Lobby}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]
  alias BattleBox.Games.RobotGame.Game

  @player_1_id Ecto.UUID.generate()
  @player_2_id Ecto.UUID.generate()

  @player_1_server_id Ecto.UUID.generate()
  @player_2_server_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    %{
      init_opts_p1: %{
        player_id: @player_1_id,
        player_server_id: @player_1_server_id,
        connection: named_proxy(:p1_connection)
      },
      init_opts_p2: %{
        player_id: @player_2_id,
        player_server_id: @player_2_server_id,
        connection: named_proxy(:p2_connection)
      }
    }
  end

  setup context do
    {:ok, p1_server} = GameEngine.start_player(context.game_engine, context.init_opts_p1)
    {:ok, p2_server} = GameEngine.start_player(context.game_engine, context.init_opts_p2)
    Process.monitor(p1_server)
    Process.monitor(p2_server)
    %{p1_server: p1_server, p2_server: p2_server}
  end

  setup do
    changeset = Lobby.changeset(%Lobby{}, %{name: "LOBBY NAME", game_type: Game})
    {:ok, lobby} = Repo.insert(changeset)
    %{lobby: lobby}
  end

  test "you can start the player server", context do
    assert Process.alive?(context.p1_server)
    assert Process.alive?(context.p2_server)
  end

  test "the player server registers in the player server registry",
       %{p1_server: p1, p2_server: p2} = context do
    assert Registry.count(context.player_registry) == 2

    assert [{^p1, %{player_id: @player_1_id}}] =
             Registry.lookup(context.player_registry, context.init_opts_p1.player_server_id)

    assert [{^p2, %{player_id: @player_2_id}}] =
             Registry.lookup(context.player_registry, context.init_opts_p2.player_server_id)
  end

  test "You can ask the game server to join a matchmaking lobby", %{p1_server: p1} = context do
    assert [] == MatchMaker.queue_for_lobby(context.game_engine, context.lobby.id)
    assert :ok = PlayerServer.join_lobby(p1, context.lobby.name)

    assert [%{player_id: @player_1_id, pid: ^p1}] =
             MatchMaker.queue_for_lobby(context.game_engine, context.lobby.id)
  end

  test "When a match is made it forwards the request to the connections",
       %{p1_server: p1, p2_server: p2} = context do
    assert :ok = PlayerServer.join_lobby(p1, context.lobby.name)
    assert :ok = PlayerServer.join_lobby(p2, context.lobby.name)
    :ok = GameEngine.force_match_make(context.game_engine)
    assert_receive {:p1_connection, {:game_request, %{game_id: game_id}}}
    assert_receive {:p2_connection, {:game_request, %{game_id: ^game_id}}}
  end
end
