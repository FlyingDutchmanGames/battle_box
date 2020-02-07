defmodule BattleBox.PlayerServer do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter], restart: :temporary

  def start_link(%{names: _} = config, %{connection: _, player_id: _} = data) do
    GenStateMachine.start_link(__MODULE__, Map.merge(config, data))
  end

  def init(%{names: names, player_id: player_id} = data) do
    Registry.register(names.player_registry, player_id, %{})
    {:ok, :options, data}
  end

  def options(:enter, _old_state, _data) do
    :keep_state_and_data
  end
end
