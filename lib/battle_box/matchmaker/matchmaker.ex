defmodule BattleBox.MatchMaker do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  def start_link(options) do
    GenStateMachine.start_link(__MODULE__, options, name: options[:name])
  end

  def init(data) do
    {:ok, :matching, data}
  end

  def matching(:enter, _old_state, data) do
    {:keep_state, data}
  end
end
