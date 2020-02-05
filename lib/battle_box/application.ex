defmodule BattleBox.Application do
  @moduledoc false
  alias BattleBox.{Repo, Endpoint, Presence, MatchMaker}
  alias BattleBox.Games.RobotGame.RobotGameSupervisor

  use Application

  def start(_type, _args) do
    children = [
      MatchMaker,
      RobotGameSupervisor,
      BattleBox.Repo,
      BattleBoxWeb.Endpoint,
      BattleBoxWeb.Presence,
    ]

    opts = [strategy: :one_for_one, name: BattleBox.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    BattleBoxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
