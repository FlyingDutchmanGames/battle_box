defmodule BattleBox.MatchMakerServerTest do
  use ExUnit.Case, async: true
  alias BattleBox.MatchMakerServer

  setup %{test: name} do
    registry_name = Module.concat(name, Registry)
    {:ok, _pid} = Registry.start_link(name: name, keys: :duplicate)
    %{registry: registry_name}
  end

  test "you can start it", %{registry: registry} do
    {:ok, pid} = MatchMakerServer.start_link(registry: registry)
    assert Process.alive?(pid)
  end
end
