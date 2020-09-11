defmodule BattleBox.Games.AiOpponentTest do
  alias BattleBox.Games.Marooned
  alias BattleBox.Games.Marooned.Ais.{WildCard, Wilson}
  import BattleBox.Games.AiOpponent
  use ExUnit.Case, async: true

  cases = [
    # asking with a nil opponent or an empty map yields all the modules
    {nil, Marooned.ais()},
    {%{}, Marooned.ais()},
    # when asking for a name it gives that module and is case sensitive
    {"wilson", [Wilson]},
    {"WIlSoN", []},
    {["wild-card", "wilson", "fake"], [WildCard, Wilson]},
    # you can filter by difficulty
    {%{"difficulty" => Wilson.difficulty()}, [Wilson]},
    {%{"difficulty" => %{"min" => WildCard.difficulty(), "max" => Wilson.difficulty()}},
     [WildCard, Wilson]},
    # You can combine filters
    {%{
       "difficulty" => %{"min" => WildCard.difficulty(), "max" => Wilson.difficulty()},
       "name" => "wilson"
     }, [Wilson]},
    # Passing Nonsense Silently discards it and does not error
    {%{"name" => "wilson", "foo" => "bar"}, [Wilson]}
  ]

  describe "oppoent_modules/2" do
    for {opponent, expected} <- cases do
      test "#{inspect(opponent)} => #{inspect(expected)}" do
        assert opponent_modules(Marooned, unquote(Macro.escape(opponent))) ==
                 {:ok, unquote(expected)}
      end
    end
  end
end
