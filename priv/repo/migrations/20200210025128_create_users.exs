defmodule BattleBox.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table("users") do
      add :github_id, :integer, null: false
      add :avatar_url, :text, null: false
      add :username, :citext, null: false

      add :is_admin, :boolean, default: false, null: false
      add :is_banned, :boolean, default: false, null: false
      timestamps()
    end

    create index("users", [:username], unique: true)
    create index("users", [:github_id], unique: true)
  end
end
