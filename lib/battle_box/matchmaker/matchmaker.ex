defmodule BattleBox.MatchMaker do
  use GenServer
  alias BattleBox.Games.RobotGame.{Game, RobotGameSupervisor}

  def join_matchmaker_queue(player_id, pid, matchmaker) do
    GenServer.call(matchmaker, {:matchmake, player_id, pid})
  end

  def start_link(%{game_server_supervisor: _} = options) do
    GenServer.start_link(__MODULE__, options, name: options[:name])
  end

  def init(data) do
    data = Map.put(data, :pending_matches, [])
    {:ok, data}
  end

  def handle_call({:matchmake, player_id, pid}, _from, %{pending_matches: []} = data) do
    {:reply, :ok, put_in(data.pending_matches, [{player_id, pid}])}
  end

  def handle_call(
        {:matchmake, player_1_id, pid_1},
        _from,
        %{pending_matches: [{player_2_id, pid_2}]} = data
      ) do
    game =
      Game.new(
        player_1: player_1_id,
        player_2: player_2_id
      )

    {:ok, _pid} =
      RobotGameSupervisor.start_game_server(%{player_1: pid_1, player_2: pid_2, game: game})

    {:reply, :ok, put_in(data.pending_matches, [])}
  end
end
