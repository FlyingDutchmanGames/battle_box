defmodule BattleBox.Repo.Migrations.CreateBots do
  use Ecto.Migration

  def change do
    create table("bots") do
      add :name, :text, null: false
      add :user_id, :uuid, null: false
      timestamps()
    end

    create index("bots", [:name], unique: true)
    create index("bots", [:user_id])
  end
end
