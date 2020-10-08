defmodule BattleBox.GameEngine.Message.GameRequest do
  @derive Jason.Encoder
  @enforce_keys [:game_server, :game_id, :game_type, :player, :accept_time, :settings]
  defstruct [:game_server, :game_id, :game_type, :player, :accept_time, :settings]
end
