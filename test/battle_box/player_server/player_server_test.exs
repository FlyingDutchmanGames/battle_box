defmodule BattleBox.PlayerServerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{GameEngine, MatchMaker, PlayerServer, Repo, Lobby}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]
  alias BattleBox.Games.RobotGame.Game

  @player_id Ecto.UUID.generate()
  @player_server_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    %{
      init_opts: %{
        player_id: @player_id,
        player_server_id: @player_server_id,
        connection: named_proxy(:connection)
      }
    }
  end

  setup do
    changeset = Lobby.changeset(%Lobby{}, %{name: "LOBBY NAME", game_type: Game})
    {:ok, lobby} = Repo.insert(changeset)
    %{lobby: lobby}
  end

  test "you can start the player server", context do
    {:ok, pid} = GameEngine.start_player(context.game_engine, context.init_opts)
    assert Process.alive?(pid)
  end

  test "the player server registers in the player server registry", context do
    assert Registry.count(context.player_registry) == 0
    {:ok, pid} = GameEngine.start_player(context.game_engine, context.init_opts)
    assert Registry.count(context.player_registry) == 1

    assert [{^pid, %{player_id: @player_id}}] =
             Registry.lookup(context.player_registry, context.init_opts.player_server_id)
  end

  test "You can ask the game server to join a matchmaking lobby", context do
    assert %Lobby{} = Lobby.get_by_name(context.lobby.name)
    {:ok, pid} = GameEngine.start_player(context.game_engine, context.init_opts)
    assert [] == MatchMaker.queue_for_lobby(context.game_engine, context.lobby.id)
    assert :ok = PlayerServer.join_lobby(pid, context.lobby.name)

    assert [%{player_id: @player_id, pid: ^pid}] =
             MatchMaker.queue_for_lobby(context.game_engine, context.lobby.id)
  end
end
