defmodule BattleBox.Repo.Migrations.CreateMaroonedGames do
  use Ecto.Migration

  defmacrop shared do
    quote do
      add :rows, :integer, null: false
      add :cols, :integer, null: false
    end
  end

  def change do
    create table("marooned_games") do
      add :game_id, :uuid, null: false

      add :events, {:array, :binary}, null: false, default: []
      add :turn, :integer, null: false

      shared()
      timestamps()
    end

    create table("marooned_settings") do
      add :arena_id, :uuid, null: false

      shared()
      timestamps()
    end

    create index("marooned_games", :game_id, unique: true)
    create index("marooned_settings", :arena_id)
  end
end
