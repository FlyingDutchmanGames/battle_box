defmodule BattleBox.GameEngineProvider.Mock do
  alias BattleBox.GameEngine.GameEngineProvider
  use Agent

  def start_link() do
    Agent.start_link(fn -> GameEngineProvider.game_engine() end, name: __MODULE__)
  end

  def game_engine do
    Agent.get(__MODULE__, & &1)
  end

  def set_game_engine(game_engine) do
    Agent.update(__MODULE__, fn _ -> game_engine end)
  end

  def reset!() do
    Agent.update(__MODULE__, fn _ -> GameEngineProvider.game_engine() end)
  end
end
