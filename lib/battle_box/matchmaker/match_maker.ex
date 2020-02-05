defmodule BattleBox.MatchMaker do
  use Supervisor
  alias BattleBox.MatchMakerServer

  @default_name MatchMaker

  def join_queue(lobby, player_id, matchmaker \\ @default_name) do
    {:ok, _registry} =
      Registry.register(registry_name(matchmaker), lobby, %{player_id: player_id})

    :ok
  end

  def dequeue_self(lobby, matchmaker \\ @default_name) do
    :ok = Registry.unregister(registry_name(matchmaker), lobby)
  end

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, @default_name)
    Supervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl true
  def init(opts) do
    children = [
      {MatchMakerServer, name: server_name(opts[:name])},
      {Registry, keys: :duplicate, name: registry_name(opts[:name])}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def server_name(name), do: Module.concat(name, Server)
  def registry_name(name), do: Module.concat(name, Registry)
end
