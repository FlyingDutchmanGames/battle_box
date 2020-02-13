defmodule BattleBox.Repo.Migrations.CreateBots do
  use Ecto.Migration

  def change do
    create table("bots") do
      add :name, :text, null: false
      add :user_id, :uuid, null: false
      add :token, :text, null: false
      timestamps()
    end

    create index("bots", [:user_id, :name], unique: true)
    create index("bots", [:token], unique: true)
  end
end
