defmodule BattleBox.MatchMaker do
  use Supervisor
  alias BattleBox.MatchMakerServer

  def join_queue(lobby, player_id, matchmaker) do
    {:ok, _registry} =
      Registry.register(registry_name(matchmaker), lobby, %{player_id: player_id})

    :ok
  end

  def dequeue_self(lobby, matchmaker) do
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
