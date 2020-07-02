defmodule BattleBox.GameEngine.AiServer do
  alias BattleBox.GameEngine
  use GenServer, restart: :temporary

  def start_link(%{names: _} = config, data) do
    data = Map.put_new(data, :ai_id, Ecto.UUID.generate())

    GenServer.start_link(__MODULE__, Map.merge(config, data),
      name: {:via, Registry, {config.names.ai_registry, data.ai_id, %{}}}
    )
  end

  def init(data) do
    {:ok, data}
  end
end
