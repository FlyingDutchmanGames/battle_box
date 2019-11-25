use Mix.Config

config :battle_box, BattleBox.Repo,
  username: "postgres",
  password: "postgres",
  database: "battle_box_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :battle_box, BattleBoxWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn
