use Mix.Config

config :battle_box,
  ecto_repos: [BattleBox.Repo]

config :battle_box, BattleBoxWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "iqMVNVqymVOjR5Q0XCxRoPlRjEItL+0+DFCcLtW6YlNJ7Wc/zgoiUiudgVeEm2UY",
  render_errors: [view: BattleBoxWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: BattleBox.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "SECRET_SALT"
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{Mix.env()}.exs"
