defmodule BattleBox.Games.RobotGame.EventHelpers do
  ## Codes

  # Causes
  @spawn 0
  @death 1
  @move 2
  @attack 3
  @suicide 4
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
  @robot_id_size 16
  @location_size 16

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

  defmacro rg_suicide(robot_id) do
    quote do: <<
            unquote(@suicide)::unquote(@code_size),
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
end
