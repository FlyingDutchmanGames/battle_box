defmodule BattleBox.GameEngine.HumanServer.HumanSupervisor do
  use DynamicSupervisor
  alias BattleBox.{GameEngine, GameEngine.HumanServer}

  def start_link(%{names: names} = opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: names.human_supervisor)
  end

  def init(opts) do
    init_arg = Map.take(opts, [:names])
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [init_arg])
  end

  def start_human(game_engine, opts) do
    human_supervisor = GameEngine.names(game_engine).human_supervisor
    opts = Map.put_new(opts, :human_server_id, Ecto.UUID.generate())
    {:ok, human_server} = DynamicSupervisor.start_child(human_supervisor, {HumanServer, opts})
    {:ok, human_server, %{human_server_id: opts.human_server_id}}
  end
end
