defmodule BattleBox.GameEngine.Message.DebugInfo do
  @enforce_keys [:game_id, :debug_info]
  defstruct [:game_id, :debug_info]
end
