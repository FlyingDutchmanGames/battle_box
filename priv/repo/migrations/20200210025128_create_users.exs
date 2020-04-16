defmodule BattleBox.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table("users") do
      add :name, :text
      add :github_id, :integer, null: false
      add :github_avatar_url, :text
      add :github_html_url, :text
      add :github_login_name, :text, null: false
      add :github_access_token, :text
      add :is_admin, :boolean, default: false, null: false
      add :is_banned, :boolean, default: false, null: false
      timestamps()
    end

    create index("users", [:github_id], unique: true)
    create index("users", [:github_login_name], unique: true)
  end
end
