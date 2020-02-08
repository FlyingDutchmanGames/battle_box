defmodule BattleBox.PlayerServerTest do
  use ExUnit.Case, async: true
  alias BattleBox.GameEngine
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

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

  test "you can start the player server", context do
    {:ok, pid} = GameEngine.start_player(context.game_engine, context.init_opts)
    assert Process.alive?(pid)
  end

  test "the game server registers in the registry", context do
    assert Registry.count(context.player_registry) == 0
    {:ok, pid} = GameEngine.start_player(context.game_engine, context.init_opts)
    assert Registry.count(context.player_registry) == 1

    assert [{^pid, %{player_id: @player_id}}] =
             Registry.lookup(context.player_registry, context.init_opts.player_server_id)
  end
end
