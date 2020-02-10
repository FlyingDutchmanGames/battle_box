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

config :battle_box, BattleBox.TcpConnectionServer, port: 4003

config :battle_box, :github,
  client_id: "TEST_GITHUB_CLIENT_ID",
  client_secret: "TEST_GITHUB_CLIENT_SECRET"

config :logger, level: :warn
