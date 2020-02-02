defmodule BattleBox.MatchMaker do
  use GenServer

  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: options[:name])
  end

  def init(data) do
    {:ok, data}
  end
end
