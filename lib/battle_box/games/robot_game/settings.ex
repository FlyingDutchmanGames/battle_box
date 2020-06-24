defmodule BattleBox.Games.RobotGame.Settings.Shared do
  defmacro fields do
    quote do
      field :spawn_every, :integer, default: 10
      field :spawn_per_player, :integer, default: 5
      field :robot_hp, :integer, default: 50
      field :max_turns, :integer, default: 100

      field :attack_damage_min, :integer, default: 8
      field :attack_damage_max, :integer, default: 10

      field :collision_damage_min, :integer, default: 5
      field :collision_damage_max, :integer, default: 5

      field :explode_damage_min, :integer, default: 15
      field :explode_damage_max, :integer, default: 15

      field :terrain, :binary, default: BattleBox.Games.RobotGame.Settings.Terrain.default()
    end
  end
end

defmodule BattleBox.Games.RobotGame.Settings do
  alias BattleBox.Arena
  alias __MODULE__.Terrain
  use Ecto.Schema
  import Ecto.Changeset
  require __MODULE__.Shared

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  def name, do: :robot_game_settings

  @shared_fields [
    :attack_damage_max,
    :attack_damage_min,
    :collision_damage_max,
    :collision_damage_min,
    :max_turns,
    :robot_hp,
    :spawn_every,
    :spawn_per_player,
    :explode_damage_max,
    :explode_damage_min,
    :terrain
  ]

  schema "robot_game_settings" do
    belongs_to :arena, Arena
    field :spawn_enabled, :boolean, default: true, virtual: true
    field :terrain_base64, :binary, default: Base.encode64(Terrain.default()), virtual: true
    __MODULE__.Shared.fields()
    timestamps()
  end

  def shared_fields, do: @shared_fields

  def changeset(settings, params \\ %{}) do
    settings
    |> cast(params, [:terrain_base64 | @shared_fields] -- [:terrain])
    |> validate_required([:terrain_base64 | @shared_fields] -- [:terrain])
    |> validate_number(:spawn_every, greater_than_or_equal_to: 1)
    |> validate_number(:spawn_per_player, greater_than_or_equal_to: 1, less_than_or_equal_to: 20)
    |> validate_number(:robot_hp, greater_than_or_equal_to: 1, less_than_or_equal_to: 100)
    |> validate_number(:max_turns, greater_than_or_equal_to: 1, less_than_or_equal_to: 500)
    |> validate_less_than_or_equal_to(:attack_damage_min, :attack_damage_max)
    |> validate_less_than_or_equal_to(:explode_damage_min, :explode_damage_max)
    |> validate_less_than_or_equal_to(:collision_damage_min, :collision_damage_max)
    |> validate_change(:terrain_base64, fn :terrain_base64, terrain_base64 ->
      with {:decode, {:ok, terrain}} <- {:decode, Base.decode64(terrain_base64)},
           {:validate, :ok} <- {:validate, Terrain.validate(terrain)} do
        []
      else
        {:decode, :error} -> [terrain_base64: "Invalid base64"]
        {:validate, {:error, error_msg}} -> [terrain_base64: error_msg]
      end
    end)
    |> prepare_changes(fn changeset ->
      if get_change(changeset, :terrain_base64) do
        {:ok, terrain} =
          changeset
          |> get_change(:terrain_base64)
          |> Base.decode64()

        changeset
        |> delete_change(:terrain_base64)
        |> put_change(:terrain, terrain)
      else
        changeset
      end
    end)
  end

  defp validate_less_than_or_equal_to(changeset, field_1, field_2) do
    if get_field(changeset, field_1) > get_field(changeset, field_2) do
      add_error(changeset, field_1, "#{field_1} must be less than or equal to #{field_2}")
    else
      changeset
    end
  end
end
