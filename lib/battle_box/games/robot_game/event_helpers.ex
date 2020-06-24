defmodule BattleBox.Games.RobotGame.EventHelpers do
  ## Codes

  # Causes
  @spawn 0
  @death 1
  @move 2
  @attack 3
  @explode 4
  @guard 5
  @noop 6

  # Effects
  @effect_move 0
  @effect_damage 1
  @effect_guard 2
  @effect_remove_robot 3
  @effect_create_robot 4

  ## Sizes
  @code_size 8
  @hp_size 16
  @robot_id_size 16
  @player_id_size 16
  @location_size 16
  @damage_amount_size 16

  defmacro rg_spawn() do
    quote do: <<unquote(@spawn)::unquote(@code_size)>>
  end

  defmacro rg_death() do
    quote do: <<unquote(@death)::unquote(@code_size)>>
  end

  defmacro rg_attack(robot_id, x, y) do
    quote do: <<
            unquote(@attack)::unquote(@code_size),
            unquote(robot_id)::unquote(@robot_id_size),
            unquote(x)::unquote(@location_size),
            unquote(y)::unquote(@location_size)
          >>
  end

  defmacro rg_move(robot_id, x, y) do
    quote do: <<
            unquote(@move)::unquote(@code_size),
            unquote(robot_id)::unquote(@robot_id_size),
            unquote(x)::unquote(@location_size),
            unquote(y)::unquote(@location_size)
          >>
  end

  defmacro rg_explode(robot_id) do
    quote do: <<
            unquote(@explode)::unquote(@code_size),
            unquote(robot_id)::unquote(@robot_id_size)
          >>
  end

  defmacro rg_guard(robot_id) do
    quote do: <<
            unquote(@guard)::unquote(@code_size),
            unquote(robot_id)::unquote(@robot_id_size)
          >>
  end

  defmacro rg_noop(robot_id) do
    quote do: <<
            unquote(@noop)::unquote(@code_size),
            unquote(robot_id)::unquote(@robot_id_size)
          >>
  end

  defmacro move_effect(robot_id, x, y) do
    quote do: <<
            unquote(@effect_move)::unquote(@code_size),
            unquote(robot_id)::unquote(@robot_id_size),
            unquote(x)::unquote(@location_size),
            unquote(y)::unquote(@location_size)
          >>
  end

  defmacro damage_effect(robot_id, amount) do
    quote do: <<
            unquote(@effect_damage)::unquote(@code_size),
            unquote(robot_id)::unquote(@robot_id_size),
            unquote(amount)::unquote(@damage_amount_size)
          >>
  end

  defmacro guard_effect(robot_id) do
    quote do: <<
            unquote(@effect_guard)::unquote(@code_size),
            unquote(robot_id)::unquote(@robot_id_size)
          >>
  end

  defmacro remove_robot_effect(robot_id) do
    quote do: <<
            unquote(@effect_remove_robot)::unquote(@code_size),
            unquote(robot_id)::unquote(@robot_id_size)
          >>
  end

  defmacro create_robot_effect(robot_id, player_id, hp, x, y) do
    quote do: <<
            unquote(@effect_create_robot)::unquote(@code_size),
            unquote(robot_id)::unquote(@robot_id_size),
            unquote(player_id)::unquote(@player_id_size),
            unquote(hp)::unquote(@hp_size),
            unquote(x)::unquote(@location_size),
            unquote(y)::unquote(@location_size)
          >>
  end
end
