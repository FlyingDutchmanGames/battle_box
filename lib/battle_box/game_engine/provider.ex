defmodule BattleBox.GameEngine.Provider do
  import BattleBox.GameEngine, only: [default_name: 0]
  use Agent

  if Mix.env() != :test do
    def game_engine, do: unquote(default_name())
  else
    def game_engine, do: Agent.get(__MODULE__, & &1)
  end

  def start_link() do
    Agent.start_link(fn -> default_name() end, name: __MODULE__)
  end

  def set_game_engine(game_engine) do
    Agent.update(__MODULE__, fn _ -> game_engine end)
  end

  def reset!() do
    Agent.update(__MODULE__, fn _ -> default_name() end)
  end
end
