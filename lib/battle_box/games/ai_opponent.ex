defmodule BattleBox.Games.AiOpponent do
  @type t :: String.t() | %{optional(String.t()) => any()}

  @callback name() :: String.t()
  @callback description() :: String.t()
  @callback difficulty() :: integer()
  @callback creator() :: String.t()
  @callback commands(map()) :: map() | {map(), any()}
  @callback initialize(map()) :: any()

  def opponent_modules(game_type, opponent \\ nil)

  def opponent_modules(game_type, nil), do: opponent_modules(game_type, %{})

  def opponent_modules(game_type, name) when is_binary(name) or is_list(name),
    do: opponent_modules(game_type, %{"name" => name})

  def opponent_modules(game_type, opponent) when is_map(opponent) do
    modules =
      opponent
      |> Map.take(["name", "difficulty"])
      |> Enum.reduce(game_type.ais(), fn
        {"name", names}, choices ->
          for choice <- choices, choice.name in List.wrap(names), do: choice

        {"difficulty", difficulty}, choices ->
          case difficulty do
            difficulty when is_integer(difficulty) ->
              for choice <- choices, choice.difficulty == difficulty, do: choice

            difficulty when is_map(difficulty) ->
              min = difficulty["min"] || 0
              max = difficulty["max"] || 999
              for choice <- choices, choice.difficulty in min..max, do: choice
          end
      end)

    {:ok, modules}
  end
end
