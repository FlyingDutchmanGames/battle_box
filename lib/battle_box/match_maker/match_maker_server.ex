defmodule BattleBox.MatchMakerServer do
  use GenServer
  alias BattleBox.GameServer.GameSupervisor
  alias BattleBox.MatchMaker.MatchMakerLogic

  @matchmake_delay_ms 100

  def force_matchmake(match_maker_server) do
    send(match_maker_server, :matchmake)
    :ok
  end

  def start_link(%{names: names} = options) do
    GenServer.start_link(__MODULE__, options, name: names.match_maker_server)
  end

  def init(data) do
    schedule_matchmake()
    {:ok, data}
  end

  def handle_info(:matchmake, %{names: names} = state) do
    get_all_lobbies(names.match_maker_registry)
    |> Enum.uniq()
    |> Enum.each(fn lobby ->
      Registry.lookup(names.match_maker_registry, lobby)
      |> Enum.map(fn {_pid, player_info} -> player_info end)
      |> MatchMakerLogic.make_matches(lobby)
      |> Enum.each(fn match_settings ->
        {:ok, pid} = GameSupervisor.start_game(names.game_supervisor, match_settings)
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
