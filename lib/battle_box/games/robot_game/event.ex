defmodule BattleBox.Games.RobotGame.Event do
  use Ecto.Type
  def type, do: :binary
  import BattleBox.Games.RobotGame.EventHelpers

  def cast(%{turn: _, seq_num: _, cause: _, effects: _} = event) do
    {:ok, event}
  end

  def dump(%{turn: turn, seq_num: seq_num, cause: cause, effects: effects}) do
    header = <<seq_num::unsigned-integer-32, turn::unsigned-integer-16>>
    cause = encode_cause(cause)
    effects = IO.iodata_to_binary(effects)

    {:ok, header <> cause <> effects}
  end

  def load(<<seq_num::unsigned-integer-32, turn::unsigned-integer-16, rest::binary>>) do
    {cause, rest} = decode_cause(rest)
    effects = decode_effects(rest)
    {:ok, %{turn: turn, seq_num: seq_num, cause: cause, effects: effects}}
  end

  defp decode_cause(<<cause::binary>>) do
    case cause do
      <<rg_spawn(), rest::binary>> ->
        {"spawn", rest}

      <<rg_death(), rest::binary>> ->
        {"death", rest}

      <<rg_move(robot_id, x, y), rest::binary>> ->
        {%{"type" => "move", "robot_id" => robot_id, "target" => [x, y]}, rest}

      <<rg_attack(robot_id, x, y), rest::binary>> ->
        {%{"type" => "attack", "robot_id" => robot_id, "target" => [x, y]}, rest}

      <<rg_explode(robot_id), rest::binary>> ->
        {%{"type" => "explode", "robot_id" => robot_id}, rest}

      <<rg_guard(robot_id), rest::binary>> ->
        {%{"type" => "guard", "robot_id" => robot_id}, rest}

      <<rg_noop(robot_id), rest::binary>> ->
        {%{"type" => "noop", "robot_id" => robot_id}, rest}
    end
  end

  defp decode_effects(effects), do: decode_effects(effects, [])
  defp decode_effects(<<>>, effects), do: effects

  defp decode_effects(effects, acc) do
    case effects do
      <<move_effect(robot_id, x, y), rest::binary>> ->
        decode_effects(rest, [move_effect(robot_id, x, y) | acc])

      <<damage_effect(robot_id, amount), rest::binary>> ->
        decode_effects(rest, [damage_effect(robot_id, amount) | acc])

      <<guard_effect(robot_id), rest::binary>> ->
        decode_effects(rest, [guard_effect(robot_id) | acc])

      <<remove_robot_effect(robot_id), rest::binary>> ->
        decode_effects(rest, [remove_robot_effect(robot_id) | acc])

      <<create_robot_effect(robot_id, player_id, hp, x, y), rest::binary>> ->
        decode_effects(rest, [create_robot_effect(robot_id, player_id, hp, x, y) | acc])
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

      %{"type" => type, "robot_id" => robot_id} when type in ["explode", "guard", "noop"] ->
        case type do
          "explode" -> rg_explode(robot_id)
          "guard" -> rg_guard(robot_id)
          "noop" -> rg_noop(robot_id)
        end
    end
  end
end
