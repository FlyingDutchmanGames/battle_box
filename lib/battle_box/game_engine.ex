defmodule BattleBox.GameEngine do
  use Supervisor
  alias BattleBox.{MatchMaker, GameServer.GameSupervisor}

  @default_name GameEngine

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, @default_name)
    Supervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(_opts) do
    children = [
      MatchMaker,
      GameSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
