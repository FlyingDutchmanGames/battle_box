defmodule BattleBox.GameEngine.Message.CommandsRequest do
  @enforce_keys [:game_id, :game_state, :maximum_time, :minimum_time, :player, :request_id]
  defstruct [:game_id, :game_state, :maximum_time, :minimum_time, :player, :request_id]
end
