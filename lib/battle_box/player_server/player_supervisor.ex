defmodule BattleBox.PlayerServer.PlayerSupervisor do
  use DynamicSupervisor
  alias BattleBox.PlayerServer

  def start_link(%{names: names} = opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: names.player_supervisor)
  end

  def init(opts) do
    init_arg = Map.take(opts, [:names])
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [init_arg])
  end

  def start_player(player_supervisor, %{connection: _} = opts) do
    DynamicSupervisor.start_child(player_supervisor, {PlayerServer, opts})
  end
end
