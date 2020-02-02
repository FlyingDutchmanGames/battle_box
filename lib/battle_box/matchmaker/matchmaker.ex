defmodule BattleBox.MatchMaker do
  use GenServer
  alias BattleBox.Games.RobotGame.{Game, RobotGameSupervisor}

  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: options[:name])
  end

  def init(data) do
    {:ok, data}
  end

  def handle_call({:matchmake, player_id, pid}, _from, nil) do
    {:reply, :ok, {player_id, pid}}
  end

  def handle_call({:matchmake, player_1_id, pid_1}, _from, {player_2_id, pid_2}) do
    game =
      Game.new(
        player_1: player_1_id,
        player_2: player_2_id
      )

    {:ok, _pid} =
      RobotGameSupervisor.start_game_server(%{player_1: pid_1, player_2: pid_2, game: game})

    {:reply, :ok, nil}
  end
end
