defmodule BattleBox.Repo.Migrations.CreateRobotGames do
  use Ecto.Migration

  def change do
    create table("robot_games") do
      add :player_1, :uuid, null: false
      add :player_2, :uuid, null: false
      add :robot_hp, :integer, null: false
      add :spawn_every, :integer, null: false
      add :spawn_per_player, :integer, null: false
      add :attack_damage, :jsonb, null: false
      add :collision_damage, :jsonb, null: false
      add :suicide_damage, :jsonb, null: false
      add :max_turns, :integer, null: false

      timestamps()
    end

    create table("robot_game_turns", primary_key: false) do
      add :game_id, :uuid, null: false, primary_key: true
      add :turn_number, :integer, null: false, primary_key: true
      add :moves, :jsonb, null: false, default: fragment("'[]'::jsonb")

      timestamps()
    end

    create index("robot_games", [:player_1])
    create index("robot_games", [:player_2])
    # create index("robot_game_turns", [:game_id, :turn_number], unique: true)
  end
end
