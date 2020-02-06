defmodule BattleBox.Application do
  use Application

  def start(_type, _args) do
    children = [
      BattleBox.GameEngine,
      BattleBox.Repo,
      BattleBoxWeb.Endpoint,
      BattleBoxWeb.Presence
    ]

    opts = [strategy: :one_for_one, name: BattleBox.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    BattleBoxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
