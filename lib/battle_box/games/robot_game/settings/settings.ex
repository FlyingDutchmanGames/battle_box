defmodule BattleBox.Games.RobotGame.Settings do
  alias __MODULE__.{Terrain, DamageModifier}
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "robot_game_settings" do
    field :spawn_every, :integer, default: 10
    field :spawn_per_player, :integer, default: 5
    field :robot_hp, :integer, default: 50
    field :max_turns, :integer, default: 100
    field :attack_damage, DamageModifier, default: %{min: 8, max: 10}
    field :collision_damage, DamageModifier, default: 5
    field :suicide_damage, DamageModifier, default: 15

    field :persistent?, :boolean, default: true, virtual: true
    field :spawn_enabled, :boolean, default: true, virtual: true
    field :terrain, :any, default: Terrain.default(), virtual: true
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
      :suicide_damage
    ])
  end

  def new(opts \\ []) do
    opts = Enum.into(opts, %{})
    opts = Map.put_new(opts, :id, Ecto.UUID.generate())

    %__MODULE__{}
    |> Map.merge(opts)
  end

  def get_by_id(id) do
    Repo.get_by(__MODULE__, id: id)
  end
end
