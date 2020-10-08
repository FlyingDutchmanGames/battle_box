defmodule BattleBox.GameEngine.Message.GameOver do
  @enforce_keys [:game_id, :score]
  defstruct [:game_id, :score]
end
