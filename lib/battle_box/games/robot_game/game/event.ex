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
      <<rg_spawn(), rest::binary>> ->
        {"spawn", rest}

      <<rg_death(), rest::binary>> ->
        {"death", rest}

      <<rg_move(robot_id, x, y), rest::binary>> ->
        {%{"type" => "move", "robot_id" => robot_id, "target" => [x, y]}, rest}

      <<rg_attack(robot_id, x, y), rest::binary>> ->
        {%{"type" => "attack", "robot_id" => robot_id, "target" => [x, y]}, rest}

      <<rg_suicide(robot_id), rest::binary>> ->
        {%{"type" => "suicide", "robot_id" => robot_id}, rest}

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
        effect = ["move", robot_id, [x, y]]
        decode_effects(rest, [effect | acc])

      <<damage_effect(robot_id, amount), rest::binary>> ->
        effect = ["damage", robot_id, amount]
        decode_effects(rest, [effect | acc])

      <<guard_effect(robot_id), rest::binary>> ->
        effect = ["guard", robot_id]
        decode_effects(rest, [effect | acc])

      <<remove_robot_effect(robot_id), rest::binary>> ->
        effect = ["remove_robot", robot_id]
        decode_effects(rest, [effect | acc])

      <<create_robot_effect(robot_id, player_id, hp, x, y), rest::binary>> ->
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
        move_effect(robot_id, x, y)

      ["damage", robot_id, amount] ->
        damage_effect(robot_id, amount)

      ["guard", robot_id] ->
        guard_effect(robot_id)

      ["remove_robot", robot_id] ->
        remove_robot_effect(robot_id)

      ["create_robot", "player_" <> player_id, robot_id, hp, [x, y]] ->
        player_id = String.to_integer(player_id)
        create_robot_effect(robot_id, player_id, hp, x, y)
    end
  end
end
