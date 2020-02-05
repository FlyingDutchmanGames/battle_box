defmodule BattleBox.Application do
  @moduledoc false
  alias BattleBox.{Repo, MatchMaker}
  alias BattleBoxWeb.{Endpoint, Presence}
  alias BattleBox.Games.RobotGame.RobotGameSupervisor

  use Application

  def start(_type, _args) do
    children = [
      MatchMaker,
      RobotGameSupervisor,
      Repo,
      Endpoint,
      Presence
    ]

    opts = [strategy: :one_for_one, name: BattleBox.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    BattleBoxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
