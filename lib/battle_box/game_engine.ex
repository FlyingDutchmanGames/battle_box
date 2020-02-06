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
        name: matchmaker_name(opts[:name]), game_supervisor: game_supervisor_name(opts[:name])
      },
      {
        GameSupervisor,
        name: game_supervisor_name(opts[:name])
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def default_name(), do: @default_name

  defp matchmaker_name(name), do: Module.concat(name, :"Elixir.MatchMaker")
  defp game_supervisor_name(name), do: Module.concat(name, :"Elixir.GameSupervisor")
end
