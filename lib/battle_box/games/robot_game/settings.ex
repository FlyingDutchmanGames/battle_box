defmodule BattleBox.Games.RobotGame.Settings.Shared do
  defmacro fields do
    quote do
      field :spawn_every, :integer, default: 10
      field :spawn_per_player, :integer, default: 5
      field :robot_hp, :integer, default: 50
      field :max_turns, :integer, default: 100

      field :attack_damage, BattleBox.Games.RobotGame.Settings.DamageModifier,
        default: %{min: 8, max: 10}

      field :collision_damage, BattleBox.Games.RobotGame.Settings.DamageModifier, default: 5
      field :suicide_damage, BattleBox.Games.RobotGame.Settings.DamageModifier, default: 15
      field :terrain, :binary, default: BattleBox.Games.RobotGame.Settings.Terrain.default()
    end
  end
end

defmodule BattleBox.Games.RobotGame.Settings do
  alias BattleBox.Lobby
  alias __MODULE__.Terrain
  use Ecto.Schema
  import Ecto.Changeset
  require __MODULE__.Shared

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  def name, do: :robot_game_settings

  @shared_fields [
    :spawn_every,
    :spawn_per_player,
    :robot_hp,
    :max_turns,
    :attack_damage,
    :collision_damage,
    :suicide_damage,
    :terrain
  ]

  schema "robot_game_settings" do
    belongs_to :lobby, Lobby
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
end
