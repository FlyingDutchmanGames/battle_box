defmodule BattleBox.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table("games") do
      add :lobby_id, :uuid
      timestamps()
    end

    create table("game_bots") do
      add :game_id, :uuid, null: false
      add :game_type, :text, null: false
      add :bot_id, :uuid, null: false
      add :player, :integer, null: false
      add :score, :integer, null: false, default: 0
      add :winner, :bool, null: false, default: false
      timestamps()
    end

    create index("games", ["lobby_id, updated_at DESC"])
    create index("game_bots", [:bot_id])
    create index("game_bots", [:game_id, :player], unique: true)
  end
end
