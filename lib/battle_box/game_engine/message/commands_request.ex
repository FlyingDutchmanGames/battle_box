defmodule BattleBox.GameEngine.Message.CommandsRequest do
  @enforce_keys [:game_id, :game_state, :maximum_time, :minimum_time, :player]
  defstruct [:game_id, :game_state, :maximum_time, :minimum_time, :player]
end
