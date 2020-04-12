defmodule BattleBox.Repo.Migrations.CreateLobbies do
  use Ecto.Migration

  def change do
    create table("lobbies") do
      add :name, :text, null: false
      add :game_type, :text, null: false
      add :game_acceptance_time_ms, :integer, null: false
      add :command_time_minimum_ms, :integer, null: false
      add :command_time_maximum_ms, :integer, null: false
      add :user_id, :uuid, null: false
      add :settings_id, :uuid, null: false
      timestamps()
    end

    create index("lobbies", [:name], unique: true)
    create index("lobbies", [:user_id])
  end
end
