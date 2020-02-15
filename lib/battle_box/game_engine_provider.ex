defmodule BattleBox.GameEngineProvider do
  def game_engine, do: BattleBox.GameEngine.default_name()
end
