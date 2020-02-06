defmodule BattleBox.MatchMakerServer do
  use GenServer

  @matchmake_delay_ms 100

  def start_link(options) do
    initial = %{
      registry: Keyword.fetch!(options, :registry)
    }

    GenServer.start_link(__MODULE__, initial, name: options[:name])
  end

  def init(data) do
    schedule_matchmake()
    {:ok, data}
  end

  def handle_info(:matchmake, %{registry: registry} = state) do
    get_all_lobbies(registry)
    |> Enum.uniq()
    # TODO: Task.async_stream with some concurrency limit?
    |> Enum.each(fn lobby ->
      :ok = match_players(Registry.lookup(registry, lobby))
    end)

    schedule_matchmake()
    {:noreply, state}
  end

  defp match_players([_player_1, _player_2 | rest]) do
    # TODO: actually match players
    match_players(rest)
  end

  defp match_players([_only_one_player]), do: :ok
  defp match_players([]), do: :ok

  defp get_all_lobbies(registry) do
    Registry.select(registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  defp schedule_matchmake do
    Process.send_after(self(), :matchmake, @matchmake_delay_ms)
  end
end
