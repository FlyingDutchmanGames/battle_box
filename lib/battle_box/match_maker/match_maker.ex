defmodule BattleBox.MatchMaker do
  use Supervisor
  alias BattleBox.MatchMakerServer
  alias BattleBox.GameEngine

  @doc """
  Joining a queue in a lobby

  Potential Gotchas:
  The registry will keep track of the registering pid, but the game will be matched to the
  pid passed as the last arg. This was done to allow a proxy to wait in line for you, and
  to make it easier to test
  """
  def join_queue(game_engine, lobby, player_id, pid \\ self()) when is_atom(game_engine) do
    {:ok, _registry} =
      Registry.register(match_maker_registry_name(game_engine), lobby, %{
        player_id: player_id,
        pid: pid
      })

    :ok
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
