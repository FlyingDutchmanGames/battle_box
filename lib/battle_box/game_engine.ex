defmodule BattleBox.GameEngine do
  use Supervisor
  alias BattleBox.GameServer.GameSupervisor, as: GameSup

  @default_name GameEngine

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, @default_name)
    Supervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    children = [
      {BattleBox.MatchMaker, %{names: names(opts[:name])}},
      {GameSup, %{names: names(opts[:name])}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def default_name(), do: @default_name

  def names(name) do
    %{
      game_engine: name,
      game_supervisor: game_supervisor_name(name),
      match_maker: match_maker_name(name),
      match_maker_server: match_maker_server_name(name),
      match_maker_registry: match_maker_registry_name(name),
    }
  end

  defp match_maker_name(name), do: Module.concat(name, MatchMaker)
  defp match_maker_server_name(name), do: Module.concat(name, MatchMaker.MatchMakerServer)
  defp match_maker_registry_name(name), do: Module.concat(name, MatchMaker.Registry)
  defp game_supervisor_name(name), do: Module.concat(name, GameSupervisor)
end
