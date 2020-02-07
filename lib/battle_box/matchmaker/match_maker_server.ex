defmodule BattleBox.MatchMakerServer do
  use GenServer
  alias BattleBox.GameServer.GameSupervisor
  alias BattleBox.MatchMaker.MatchMakerLogic

  @matchmake_delay_ms 100

  def force_matchmake(match_maker_server) do
    send(match_maker_server, :matchmake)
    :ok
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
      |> Enum.map(fn {_pid, player_info} -> player_info end)
      |> MatchMakerLogic.make_matches(lobby)
      |> Enum.each(fn match_settings -> GameSupervisor.start_game(game_sup, match_settings) end)
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
