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
    |> Enum.each(fn lobby ->
      lobby = Lobby.get_by_name(lobby)
      :ok = match_players(lobby.game_type, Registry.lookup(registry, lobby))
    end)

    schedule_matchmake()
    {:noreply, state}
  end

  defp match_players(game_module, [_player_1, _player_2 | rest]) do
    match_players(game_module, rest)
  end

  defp match_players(_, [_only_one_player]), do: :ok
  defp match_players(_, []), do: :ok

  defp get_all_lobbies(registry) do
    Registry.select(registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  defp schedule_matchmake do
    Process.send_after(self(), :matchmake, @matchmake_delay_ms)
  end
end
