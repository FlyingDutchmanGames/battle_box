defmodule BattleBox.GameEngine.Message.GameCanceled do
  @enforce_keys [:game_id]
  defstruct [:game_id]
end
