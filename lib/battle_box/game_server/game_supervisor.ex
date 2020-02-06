defmodule BattleBox.GameServer.GameSupervisor do
  use DynamicSupervisor

  @default_name GameSupervisor

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, @default_name)
    DynamicSupervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
