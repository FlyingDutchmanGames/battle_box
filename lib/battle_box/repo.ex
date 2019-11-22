defmodule BattleBox.Repo do
  use Ecto.Repo,
    otp_app: :battle_box,
    adapter: Ecto.Adapters.Postgres
end
