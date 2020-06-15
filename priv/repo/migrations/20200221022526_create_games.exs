defmodule BattleBox.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table("games") do
      add :lobby_id, :uuid
      add :game_type, :text, null: false
      timestamps()
    end

    create table("game_bots") do
      add :game_id, :uuid, null: false
      add :bot_id, :uuid, null: false
      add :player, :integer, null: false
      add :score, :integer, null: false
      add :winner, :boolean, null: false, default: false
      timestamps()
    end

    create index("games", :inserted_at)
    create index("games", :lobby_id)
    create index("game_bots", [:bot_id])
    create index("game_bots", [:game_id, :player], unique: true)
  end
end
