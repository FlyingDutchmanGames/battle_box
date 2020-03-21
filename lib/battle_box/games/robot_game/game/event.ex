defmodule BattleBox.Games.RobotGame.Event do
  use Ecto.Type
  def type, do: :binary
  import BattleBox.Games.RobotGame.EventHelpers

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

  def cast(%{turn: _, seq_num: _, cause: _, effects: _} = event) do
    {:ok, event}
  end

  def dump(%{turn: turn, seq_num: seq_num, cause: cause, effects: effects}) do
    header = <<seq_num::unsigned-integer-32, turn::unsigned-integer-16>>
    cause = encode_cause(cause)

    effects =
      effects
      |> Enum.map(&encode_effect/1)
      |> IO.iodata_to_binary()

    {:ok, header <> cause <> effects}
  end

  def load(<<seq_num::unsigned-integer-32, turn::unsigned-integer-16, rest::binary>>) do
    {cause, rest} = decode_cause(rest)
    effects = decode_effects(rest)
    {:ok, %{turn: turn, seq_num: seq_num, cause: cause, effects: effects}}
  end

  defp decode_cause(<<cause::binary>>) do
    case cause do
      <<@spawn::unsigned-integer-8, rest::binary>> ->
        {"spawn", rest}

      <<@death::unsigned-integer-8, rest::binary>> ->
        {"death", rest}

      <<
        code::unsigned-integer-8,
        robot_id::unsigned-integer-16,
        x::unsigned-integer-16,
        y::unsigned-integer-16,
        rest::binary
      >>
      when code in [@move, @attack] ->
        type = %{@move => "move", @attack => "attack"}[code]
        {%{"type" => type, "robot_id" => robot_id, "target" => [x, y]}, rest}

      <<
        code::unsigned-integer-8,
        robot_id::unsigned-integer-16,
        rest::binary
      >>
      when code in [@suicide, @guard, @noop] ->
        type = %{@suicide => "suicide", @guard => "guard", @noop => "noop"}[code]
        {%{"type" => type, "robot_id" => robot_id}, rest}
    end
  end

  defp decode_effects(effects), do: decode_effects(effects, [])
  defp decode_effects(<<>>, effects), do: effects

  defp decode_effects(effects, acc) do
    case effects do
      <<
        @effect_move::unsigned-integer-8,
        robot_id::unsigned-integer-16,
        x::unsigned-integer-16,
        y::unsigned-integer-16,
        rest::binary
      >> ->
        effect = ["move", robot_id, [x, y]]
        decode_effects(rest, [effect | acc])

      <<
        @effect_damage::unsigned-integer-8,
        robot_id::unsigned-integer-16,
        amount::unsigned-integer-16,
        rest::binary
      >> ->
        effect = ["damage", robot_id, amount]
        decode_effects(rest, [effect | acc])

      <<
        @effect_guard::unsigned-integer-8,
        robot_id::unsigned-integer-16,
        rest::binary
      >> ->
        effect = ["guard", robot_id]
        decode_effects(rest, [effect | acc])

      <<
        @effect_remove_robot::unsigned-integer-8,
        robot_id::unsigned-integer-16,
        rest::binary
      >> ->
        effect = ["remove_robot", robot_id]
        decode_effects(rest, [effect | acc])

      <<
        @effect_create_robot::unsigned-integer-8,
        player_id::unsigned-integer-8,
        robot_id::unsigned-integer-16,
        hp::unsigned-integer-16,
        x::unsigned-integer-16,
        y::unsigned-integer-16,
        rest::binary
      >> ->
        effect = ["create_robot", "player_#{player_id}", robot_id, hp, [x, y]]
        decode_effects(rest, [effect | acc])
    end
  end

  defp encode_cause(cause) do
    case cause do
      "spawn" ->
        rg_spawn()

      "death" ->
        rg_death()

      %{"type" => type, "robot_id" => robot_id, "target" => [x, y]}
      when type in ["move", "attack"] ->
        case type do
          "move" -> rg_move(robot_id, x, y)
          "attack" -> rg_attack(robot_id, x, y)
        end

      %{"type" => type, "robot_id" => robot_id} when type in ["suicide", "guard", "noop"] ->
        case type do
          "suicide" -> rg_suicide(robot_id)
          "guard" -> rg_guard(robot_id)
          "noop" -> rg_noop(robot_id)
        end
    end
  end

  defp encode_effect(effect) do
    case effect do
      ["move", robot_id, [x, y]] ->
        <<
          @effect_move::unsigned-integer-8,
          robot_id::unsigned-integer-16,
          x::unsigned-integer-16,
          y::unsigned-integer-16
        >>

      ["damage", robot_id, amount] ->
        <<
          @effect_damage::unsigned-integer-8,
          robot_id::unsigned-integer-16,
          amount::unsigned-integer-16
        >>

      ["guard", robot_id] ->
        <<@effect_guard::unsigned-integer-8, robot_id::unsigned-integer-16>>

      ["remove_robot", robot_id] ->
        <<@effect_remove_robot::unsigned-integer-8, robot_id::unsigned-integer-16>>

      ["create_robot", "player_" <> player_id, robot_id, hp, [x, y]] ->
        player_id = String.to_integer(player_id)

        <<
          @effect_create_robot::unsigned-integer-8,
          player_id::unsigned-integer-8,
          robot_id::unsigned-integer-16,
          hp::unsigned-integer-16,
          x::unsigned-integer-16,
          y::unsigned-integer-16
        >>
    end
  end
end
