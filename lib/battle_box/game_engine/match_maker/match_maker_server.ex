defmodule BattleBox.GameEngine.MatchMakerServer do
  use GenServer
  alias BattleBox.{GameEngine, Arena, Repo}
  alias BattleBox.GameEngine.{MatchMaker, MatchMaker.MatchMakerLogic}

  @match_make_delay_ms 100

  def force_match_make(game_engine) do
    match_maker_server = GameEngine.names(game_engine).match_maker_server
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
    arenas =
      names.game_engine
      |> MatchMaker.arenas_with_queued_players()
      |> Enum.map(&Repo.get!(Arena, &1))
      |> Repo.preload(:user)
      |> Enum.map(&Arena.preload_game_settings/1)

    for arena <- arenas do
      queue =
        MatchMaker.queue_for_arena(names.game_engine, arena.id)
        |> Enum.map(fn request ->
          update_in(request.bot, &Repo.preload(&1, :user))
        end)

      MatchMakerLogic.make_matches(queue, arena)
      |> Enum.each(fn match_settings ->
        {:ok, _pid} = GameEngine.start_game(names.game_engine, match_settings)
      end)
    end

    schedule_match_make()
    {:noreply, state}
  end

  defp schedule_match_make do
    Process.send_after(self(), :match_make, @match_make_delay_ms)
  end
end
