use Mix.Config

envs =
  [
    username: "BATTLE_BOX_DB_USER",
    password: "BATTLE_BOX_DB_PASS",
    hostname: "BATTLE_BOX_DB_HOST",
    database: "BATTLE_BOX_DB_DATABASE",
    secret_key_base: "BATTLE_BOX_SECRET_KEY_BASE",
    github_client_id: "BATTLE_BOX_GITHUB_CLIENT_ID",
    github_client_secret: "BATTLE_BOX_GITHUB_CLIENT_SECRET"
  ]
  |> Enum.map(fn {key, env} -> {key, System.fetch_env!(env)} end)

config :battle_box, BattleBox.Repo,
  username: envs[:username],
  hostname: envs[:hostname],
  password: envs[:password],
  database: envs[:database],
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :battle_box, BattleBoxWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
  secret_key_base: envs[:secret_key_base]

config :battle_box, :github,
  client_id: envs[:github_client_id],
  client_secret: envs[:github_client_secret]
