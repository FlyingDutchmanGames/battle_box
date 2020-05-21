defmodule BattleBox.Repo.Migrations.CreateRobotGames do
  use Ecto.Migration

  defmacrop shared do
    quote do
      add :robot_hp, :integer, null: false
      add :spawn_every, :integer, null: false
      add :spawn_per_player, :integer, null: false
      add :attack_damage, :jsonb, null: false
      add :collision_damage, :jsonb, null: false
      add :suicide_damage, :jsonb, null: false
      add :max_turns, :integer, null: false
      add :terrain, :binary, null: false
    end
  end

  def change do
    create table("robot_games") do
      add :game_id, :uuid, null: true

      add :events, {:array, :binary}, null: false, default: []
      add :turn, :integer, null: false

      shared()
      timestamps()
    end

    create table("robot_game_settings") do
      add :lobby_id, :uuid, null: false

      shared()
      timestamps()
    end
  end
end
