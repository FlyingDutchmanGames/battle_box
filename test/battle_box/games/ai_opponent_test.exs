defmodule BattleBox.Games.AiOpponentTest do
  alias BattleBox.Games.RobotGame
  alias BattleBox.Games.RobotGame.Ais.{Kansas, Tortuga, HoneyBadger}
  import BattleBox.Games.AiOpponent
  use ExUnit.Case, async: true

  cases = [
    # asking with a nil opponent or an empty map yields all the modules
    {nil, RobotGame.ais()},
    {%{}, RobotGame.ais()},
    # when asking for a name it gives that module and is case sensitive
    {"kansas", [Kansas]},
    {"KaNsaS", []},
    {["kansas", "honey-badger", "fake"], [Kansas, HoneyBadger]},
    # you can filter by difficulty
    {%{"difficulty" => Tortuga.difficulty()}, [Tortuga]},
    {%{"difficulty" => %{"min" => Tortuga.difficulty(), "max" => Kansas.difficulty()}},
     [Tortuga, Kansas]},
    # You can combine filters
    {%{
       "difficulty" => %{"min" => Tortuga.difficulty(), "max" => Kansas.difficulty()},
       "name" => "kansas"
     }, [Kansas]},
    # Passing Nonsense Silently discards it and does not error
    {%{"name" => "kansas", "foo" => "bar"}, [Kansas]}
  ]

  describe "oppoent_modules/2" do
    for {opponent, expected} <- cases do
      test "#{inspect(opponent)} => #{inspect(expected)}" do
        assert opponent_modules(RobotGame, unquote(Macro.escape(opponent))) ==
                 {:ok, unquote(expected)}
      end
    end
  end
end
