defmodule BattleBox.Games.RobotGame.Settings.SharedSettings do
  def shared_robot_game_settings_fields do
    [
      :spawn_every,
      :spawn_per_player,
      :robot_hp,
      :max_turns,
      :attack_damage,
      :collision_damage,
      :suicide_damage,
      :terrain
    ]
  end

  defmacro shared_robot_game_settings_schema_fields do
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
