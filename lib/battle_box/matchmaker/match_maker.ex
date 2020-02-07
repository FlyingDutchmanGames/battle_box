defmodule BattleBox.MatchMaker do
  use Supervisor
  alias BattleBox.MatchMakerServer

  @doc """
  Joining a queue in a lobby

  Potential Gotchas:
  The registry will keep track of the registering pid, but the game will be matched to the
  pid passed as the last arg. This was done to allow a proxy to wait in line for you, and
  to make it easier to test
  """
  def join_queue(matchmaker, lobby, player_id, pid \\ self()) when is_atom(matchmaker) do
    {:ok, _registry} =
      Registry.register(registry_name(matchmaker), lobby, %{player_id: player_id, pid: pid})

    :ok
  end

  def dequeue_self(matchmaker, lobby) when is_atom(matchmaker) do
    :ok = Registry.unregister(registry_name(matchmaker), lobby)
  end

  def start_link(%{name: name, game_supervisor: _} = opts) do
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  def init(%{name: name, game_supervisor: game_supervisor}) do
    children = [
      {MatchMakerServer,
       %{
         name: server_name(name),
         registry: registry_name(name),
         game_supervisor: game_supervisor
       }},
      {Registry, keys: :duplicate, name: registry_name(name)}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def server_name(name), do: Module.concat(name, Server)
  def registry_name(name), do: Module.concat(name, Registry)
end
