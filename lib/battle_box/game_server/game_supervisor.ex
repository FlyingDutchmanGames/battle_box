defmodule BattleBox.GameServer.GameSupervisor do
  use DynamicSupervisor

  def start_link(%{name: name} = opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: name)
  end

  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
