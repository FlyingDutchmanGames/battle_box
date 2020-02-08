defmodule BattleBox.Repo.Migrations.CreateLobbies do
  use Ecto.Migration

  def change do
    create table("lobbies") do
      add :name, :text, null: false
      add :game_type, :text, null: false
      add :game_acceptance_timeout_ms, :integer, null: false
      timestamps()
    end

    create index("lobbies", [:name], unique: true)
  end
end
