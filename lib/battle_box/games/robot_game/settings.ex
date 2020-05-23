defmodule BattleBox.Games.RobotGame.Settings do
  alias BattleBox.{Repo, Lobby}
  import __MODULE__.SharedSettings
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  def name, do: :robot_game_settings

  schema "robot_game_settings" do
    belongs_to :lobby, Lobby

    field :persistent?, :boolean, default: true, virtual: true
    field :spawn_enabled, :boolean, default: true, virtual: true
    shared_robot_game_settings_schema_fields()
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
