defmodule BattleBox.MatchMakerServer do
  use GenServer
  alias BattleBox.GameServer.GameSupervisor
  alias BattleBox.Games.RobotGame.Game

  @matchmake_delay_ms 100

  def force_matchmake(match_maker_server) do
    send(match_maker_server, :matchmake)
  end

  def start_link(%{name: _, registry: _, game_supervisor: _} = options) do
    GenServer.start_link(__MODULE__, options, name: options[:name])
  end

  def init(data) do
    schedule_matchmake()
    {:ok, data}
  end

  def handle_info(:matchmake, %{registry: registry, game_supervisor: game_sup} = state) do
    get_all_lobbies(registry)
    |> Enum.uniq()
    |> Enum.each(fn lobby ->
      Registry.lookup(registry, lobby)
      |> Enum.chunk_every(2)
      |> Enum.each(fn
        [{pid_1, %{player_id: player_1_id}}, {pid_2, %{player_id: player_2_id}}] ->
          game_start_options = %{
            game: Game.new(player_1: player_1_id, player_2: player_2_id),
            player_1: pid_1,
            player_2: pid_2
          }

          {:ok, _} = GameSupervisor.start_game(game_sup, game_start_options)

          :ok

        _ ->
          :ok
      end)
    end)

    schedule_matchmake()
    {:noreply, state}
  end

  defp get_all_lobbies(registry) do
    Registry.select(registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  defp schedule_matchmake do
    Process.send_after(self(), :matchmake, @matchmake_delay_ms)
  end
end
