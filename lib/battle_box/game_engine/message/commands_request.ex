defmodule BattleBox.GameEngine.Message.CommandsRequest do
  @derive Jason.Encoder
  @enforce_keys [
    :game_id,
    :game_state,
    :maximum_time,
    :minimum_time,
    :player,
    :request_id,
    :score
  ]
  defstruct @enforce_keys
end
