defmodule BattleBox.MatchMaker do
  use Supervisor
  alias BattleBox.MatchMakerServer

  @default_name MatchMaker

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

    @impl true
  def init(opts) do
    name = opts[:name] || @default_name

    children = [
      {MatchMakerServer, name: match_maker_server_name(name)},
      {Registry, keys: :duplicate, name: match_maker_registry_name(name)} 
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp match_maker_server_name(name), do: Module.concat(name, Server)
  defp match_maker_registry_name(name), do: Module.concat(name, Registry)
end
