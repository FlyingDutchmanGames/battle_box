defmodule BattleBox.GameEngine.AiServer do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter], restart: :temporary

  def start_link(%{names: _} = config, %{logic_module: _} = data) do
    data = Map.put_new(data, :ai_id, Ecto.UUID.generate())

    GenStateMachine.start_link(__MODULE__, Map.merge(config, data),
      name: {:via, Registry, {config.names.ai_registry, data.ai_id, %{}}}
    )
  end

  def init(data) do
    {:ok, :options, data}
  end
end
