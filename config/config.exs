use Mix.Config

alias BattleBox.Games.Marooned

config :battle_box,
  ecto_repos: [BattleBox.Repo],
  generators: [binary_id: true]

config :battle_box, BattleBox.Repo, migration_primary_key: [name: :id, type: :binary_id]

config :battle_box, BattleBoxWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "iqMVNVqymVOjR5Q0XCxRoPlRjEItL+0+DFCcLtW6YlNJ7Wc/zgoiUiudgVeEm2UY",
  render_errors: [view: BattleBoxWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: BattleBox.PubSub,
  live_view: [
    signing_salt: "SECRET_SALT"
  ]

config :battle_box, BattleBox.GameEngine, games: [Marooned]

config :battle_box, BattleBox.TcpConnectionServer, port: 4001

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :tesla, :adapter, Tesla.Adapter.Gun

import_config "#{Mix.env()}.exs"
