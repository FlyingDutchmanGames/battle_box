defmodule BattleBox.MatchMakerServer do
  use GenServer
  alias BattleBox.Games.RobotGame.{Game, RobotGameSupervisor}

  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: options[:name])
  end

  def init(data) do
    {:ok, data}
  end
end
