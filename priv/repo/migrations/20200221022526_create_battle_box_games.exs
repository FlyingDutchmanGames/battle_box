defmodule BattleBox.Repo.Migrations.CreateBattleBoxGames do
  use Ecto.Migration

  def change do
    create table("battle_box_games") do
      add :winner_id, :uuid
      add :lobby_id, :uuid, null: false
      timestamps()
    end

    create table("battle_box_game_bots") do
      add :battle_box_game_id, :uuid, null: false
      add :bot_id, :uuid, null: false
      add :player, :text, null: false
      add :score, :integer, null: false, default: 0
      timestamps()
    end

    create index("battle_box_games", [:lobby_id])
    create index("battle_box_game_bots", [:battle_box_game_id, :bot_id], unique: true)
    create index("battle_box_game_bots", [:bot_id, :battle_box_game_id], unique: true)
  end
end