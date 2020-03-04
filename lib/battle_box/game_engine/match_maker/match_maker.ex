defmodule BattleBox.GameEngine.MatchMaker do
  use Supervisor
  alias BattleBox.{Bot, GameEngine, GameEngine.MatchMakerServer}

  @doc """
  Joining a queue in a lobby

  Potential Gotchas:
  The registry will keep track of the registering pid, but the game will be matched to the
  pid passed as the last arg. This was done to allow a proxy to wait in line for you, and
  to make it easier to test
  """
  def join_queue(game_engine, lobby, %Bot{} = bot, pid \\ self()) when is_atom(game_engine) do
    {:ok, _registry} =
      Registry.register(match_maker_registry_name(game_engine), lobby, %{
        bot: bot,
        pid: pid
      })

    :ok
  end

  def queue_for_lobby(game_engine, lobby) do
    Registry.lookup(match_maker_registry_name(game_engine), lobby)
    |> Enum.map(fn {enqueuer_pid, match_details} ->
      Map.put(match_details, :enqueuer_pid, enqueuer_pid)
    end)
  end

  def lobbies_with_queued_players(game_engine) do
    Registry.select(match_maker_registry_name(game_engine), [{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.uniq()
  end

  def dequeue_self(game_engine, lobby) when is_atom(game_engine) do
    :ok = Registry.unregister(match_maker_registry_name(game_engine), lobby)
  end

  def start_link(%{names: names} = opts) do
    Supervisor.start_link(__MODULE__, opts, name: names.match_maker)
  end

  def init(%{names: names}) do
    children = [
      {MatchMakerServer, %{names: names}},
      {Registry, keys: :duplicate, name: names.match_maker_registry}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp match_maker_registry_name(game_engine) do
    GameEngine.names(game_engine).match_maker_registry
  end
end
