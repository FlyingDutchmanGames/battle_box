defmodule BattleBox.MatchMakerServer do
  use GenServer
  alias BattleBox.GameServer.GameSupervisor
  alias BattleBox.{MatchMaker, MatchMaker.MatchMakerLogic}

  @match_make_delay_ms 100

  def force_match_make(match_maker_server) do
    send(match_maker_server, :match_make)
    :ok
  end

  def start_link(%{names: names} = options) do
    GenServer.start_link(__MODULE__, options, name: names.match_maker_server)
  end

  def init(data) do
    schedule_match_make()
    {:ok, data}
  end

  def handle_info(:match_make, %{names: names} = state) do
    MatchMaker.lobbies_with_queued_players(names.game_engine)
    |> Enum.each(fn lobby ->
      MatchMaker.queue_for_lobby(names.game_engine, lobby)
      |> MatchMakerLogic.make_matches(lobby)
      |> Enum.each(fn match_settings ->
        {:ok, _pid} = GameSupervisor.start_game(names.game_supervisor, match_settings)
      end)
    end)

    schedule_match_make()
    {:noreply, state}
  end

  defp schedule_match_make do
    Process.send_after(self(), :match_make, @match_make_delay_ms)
  end
end
