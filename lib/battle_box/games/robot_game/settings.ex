defmodule BattleBox.Games.RobotGame.Settings do
  alias BattleBox.{Repo, Lobby}
  alias __MODULE__.{Terrain, DamageModifier}
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  def name, do: :robot_game_settings

  schema "robot_game_settings" do
    belongs_to :lobby, Lobby

    field :spawn_every, :integer, default: 10
    field :spawn_per_player, :integer, default: 5
    field :robot_hp, :integer, default: 50
    field :max_turns, :integer, default: 100
    field :attack_damage, DamageModifier, default: %{min: 8, max: 10}
    field :collision_damage, DamageModifier, default: 5
    field :suicide_damage, DamageModifier, default: 15
    field :terrain, :binary, default: Terrain.default()

    field :persistent?, :boolean, default: true, virtual: true
    field :spawn_enabled, :boolean, default: true, virtual: true

    timestamps()
  end

  def changeset(settings, params \\ %{}) do
    settings
    |> cast(params, [
      :spawn_every,
      :spawn_per_player,
      :robot_hp,
      :max_turns,
      :attack_damage,
      :collision_damage,
      :suicide_damage,
      :terrain
    ])
  end
end
