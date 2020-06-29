defmodule BattleBox.GameEngine.AiServer do
  alias BattleBox.GameEngine
  use GenStateMachine, callback_mode: [:handle_event_function], restart: :temporary

  def get_bot_server_info(ai_server, timeout \\ 5000) do
    GenStateMachine.call(ai_server, :get_bot_server, timeout)
  end

  def start_link(%{names: _} = config, %{bot: _, arena: _, logic_module: _} = data) do
    data = Map.put_new(data, :ai_id, Ecto.UUID.generate())

    GenStateMachine.start_link(__MODULE__, Map.merge(config, data),
      name: {:via, Registry, {config.names.ai_registry, data.ai_id, %{}}}
    )
  end

  def init(%{bot: bot, arena: arena} = data) do
    {:ok, pid, %{bot_server_id: id}} =
      GameEngine.start_bot(data.names.game_engine, %{arena: arena, bot: bot, connection: self()})

    data =
      Map.put(data, :bot_server, %{
        pid: pid,
        id: id
      })

    {:ok, :waiting, data}
  end

  def handle_event({:call, from}, :get_bot_server, _state, data) do
    {:keep_state_and_data, {:reply, from, {:ok, data.bot_server}}}
  end
end
