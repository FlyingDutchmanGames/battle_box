defmodule BattleBox.Application do
  use Application

  def start(_type, _args) do
    children = [
      BattleBox.Repo,
      BattleBox.Release.Migrator,
      BattleBox.GameEngine,
      {Phoenix.PubSub, [name: BattleBox.PubSub, adapter: Phoenix.PubSub.PG2]},
      BattleBoxWeb.Endpoint,
      {BattleBox.Release.Seeder, skip_seed?: skip_seed?()},
      BattleBoxWeb.Telemetry,
      {BattleBox.TcpConnectionServer, port: tcp_connection_server_port()}
    ]

    opts = [strategy: :one_for_one, name: BattleBox.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    BattleBoxWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp tcp_connection_server_port do
    Application.fetch_env!(:battle_box, BattleBox.TcpConnectionServer)
    |> Keyword.fetch!(:port)
  end

  def skip_seed? do
    Application.get_env(:battle_box, BattleBox.Release.Seeder)[:skip_seed] == true
  end
end
