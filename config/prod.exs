use Mix.Config

config :battle_box, BattleBoxWeb.Endpoint,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

config :battle_box, BattleBoxWeb.Endpoint, server: true
