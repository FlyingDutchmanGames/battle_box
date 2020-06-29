defmodule BattleBox.GameEngine.AiServer.AiSupervisor do
  alias BattleBox.{GameEngine, GameEngine.AiServer}
  use DynamicSupervisor

  def start_link(%{names: names} = opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: names.ai_supervisor)
  end

  def init(opts) do
    init_arg = Map.take(opts, [:names])
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [init_arg])
  end

  def start_ai(game_engine, %{logic_module: _} = opts) do
    ai_supervisor = GameEngine.names(game_engine).ai_supervisor
    {:ok, ai_server_pid} = DynamicSupervisor.start_child(ai_supervisor, {AiServer, opts})
    {:ok, bot_server_info} = AiServer.get_bot_server_info(ai_server_pid)
    {:ok, ai_server_pid, %{bot_server: bot_server_info}}
  end
end
