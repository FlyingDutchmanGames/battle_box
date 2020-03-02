import Config

envs =
  [
    host: "BATTLE_BOX_HOST",
    database_url: "BATTLE_BOX_DATABASE_URL",
    secret_key_base: "BATTLE_BOX_SECRET_KEY_BASE",
    live_view_salt: "BATTLE_BOX_LIVE_VIEW_SALT",
    github_client_id: "BATTLE_BOX_GITHUB_CLIENT_ID",
    github_client_secret: "BATTLE_BOX_GITHUB_CLIENT_SECRET"
  ]
  |> Enum.map(fn {key, env} -> {key, System.fetch_env!(env)} end)

config :battle_box, BattleBox.Repo,
  url: envs[:database_url],
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :battle_box, BattleBoxWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
  url: [host: envs[:host], scheme: "https", port: 443],
  secret_key_base: envs[:secret_key_base],
  live_view: [signing_salt: envs[:live_view_salt]]

config :battle_box, :github,
  client_id: envs[:github_client_id],
  client_secret: envs[:github_client_secret]
