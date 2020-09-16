defmodule BattleBox.Repo.Migrations.CreateArenas do
  use Ecto.Migration

  def change do
    create table("arenas") do
      add :name, :citext, null: false
      add :user_id, :uuid, null: false
      add :description, :text

      add :game_type, :text, null: false
      add :game_acceptance_time_ms, :integer, null: false
      add :command_time_minimum_ms, :integer, null: false
      add :command_time_maximum_ms, :integer, null: false

      add :bot_self_play, :boolean, null: false
      add :user_self_play, :boolean, null: false

      timestamps()
    end

    create index("arenas", [:name], unique: true)
    create index("arenas", [:user_id, :inserted_at])
  end
end
