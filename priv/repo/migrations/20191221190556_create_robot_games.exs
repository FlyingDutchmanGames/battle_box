defmodule BattleBox.Repo.Migrations.CreateRobotGames do
  use Ecto.Migration

  def change do
    create table("robot_games") do
      add :player_1, :uuid, null: false
      add :player_2, :uuid, null: false
      add :robot_hp, :integer, null: false
      add :events, :jsonb, null: false, default: fragment("'[]'::jsonb")
      add :turn, :integer, null: false
      add :spawn_enabled, :boolean, null: false, default: true
      add :spawn_every, :integer, null: false
      add :spawn_per_player, :integer, null: false
      add :attack_damage, :jsonb, null: false
      add :collision_damage, :jsonb, null: false
      add :suicide_damage, :jsonb, null: false
      add :max_turns, :integer, null: false

      timestamps()
    end

    create index("robot_games", [:player_1])
    create index("robot_games", [:player_2])
  end
end
