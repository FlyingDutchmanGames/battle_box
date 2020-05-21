defmodule BattleBox.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table("users") do
      add :github_id, :integer, null: false
      add :avatar_url, :text, null: false
      add :user_name, :text, null: false

      add :is_admin, :boolean, default: false, null: false
      add :is_banned, :boolean, default: false, null: false
      timestamps()
    end

    create index("users", [:github_id], unique: true)
    create index("users", [:user_name], unique: true)
  end
end
