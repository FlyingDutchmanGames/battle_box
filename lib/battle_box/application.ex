defmodule BattleBox.Application do
  use Application
  alias BattleBox.TcpConnections.ConnectionHandler

  def start(_type, _args) do
    children = [
      BattleBox.GameEngine,
      BattleBox.Repo,
      BattleBoxWeb.Endpoint,
      BattleBoxWeb.Presence,
      :ranch.child_spec(Connection, :ranch_tcp, [port: 4001], ConnectionHandler, [])
    ]

    opts = [strategy: :one_for_one, name: BattleBox.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    BattleBoxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
