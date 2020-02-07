defmodule BattleBox.GameEngine do
  use Supervisor
  alias BattleBox.{MatchMaker, GameServer.GameSupervisor}

  @default_name GameEngine

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, @default_name)
    Supervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    children = [
      {
        MatchMaker,
        %{name: matchmaker_name(opts[:name]), game_supervisor: game_supervisor_name(opts[:name])}
      },
      {
        GameSupervisor,
        %{name: game_supervisor_name(opts[:name])}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def default_name(), do: @default_name

  def names(name) do
    %{
      matchmaker: matchmaker_name(name),
      matchmaker_server: matchmaker_server_name(name),
      matchmaker_registry: matchmaker_registry_name(name),
      game_supervisor: game_supervisor_name(name)
    }
  end

  def matchmaker_name(name), do: Module.concat(name, :"Elixir.MatchMaker")
  def matchmaker_server_name(name), do: MatchMaker.server_name(matchmaker_name(name))
  def matchmaker_registry_name(name), do: MatchMaker.registry_name(matchmaker_name(name))
  def game_supervisor_name(name), do: Module.concat(name, :"Elixir.GameSupervisor")
end
