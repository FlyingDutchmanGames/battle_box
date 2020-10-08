defmodule BattleBox.GameEngine.Message.GameInfo do
  @enforce_keys [:game_id, :game_info]
  defstruct [:game_id, :game_info]
end
