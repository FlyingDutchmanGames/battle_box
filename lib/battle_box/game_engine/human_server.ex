defmodule BattleBox.GameEngine.HumanServer do
  use GenStateMachine, callback_mode: [:handle_event_function], restart: :temporary

  def start_link(%{names: _} = config, opts) do
    opts = Map.put_new(opts, :human_server_id, Ecto.UUID.generate())

    GenStateMachine.start_link(__MODULE__, Map.merge(config, opts),
      name:
        {:via, Registry,
         {config.names.human_registry, opts.human_server_id,
          %{started_at: NaiveDateTime.utc_now()}}}
    )
  end

  def init(data) do
    {:ok, :unconnected, data}
  end
end
