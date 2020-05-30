defmodule BattleBox.Repo.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table("api_keys") do
      add :name, :citext, null: false
      add :hashed_token, :bytea, null: false
      add :user_id, :uuid, null: false
      add :last_used, :timestamp
      timestamps()
    end

    create index("api_keys", [:hashed_token], unique: true)
    create index("api_keys", [:user_id])
  end
end
