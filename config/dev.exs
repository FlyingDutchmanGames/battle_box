use Mix.Config

config :battle_box, BattleBox.Repo,
  username: "postgres",
  password: "postgres",
  database: "battle_box_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 5

config :battle_box, BattleBoxWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

config :battle_box, BattleBoxWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/battle_box_web/{live,views}/.*(ex)$",
      ~r"lib/battle_box_web/templates/.*(eex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

import_config "#{Mix.env()}.secret.exs"
