defmodule BattleBox.GameEngine.Message.DebugInfo do
  @derive Jason.Encoder
  @enforce_keys [:game_id, :debug_info]
  defstruct [:game_id, :debug_info]
end
