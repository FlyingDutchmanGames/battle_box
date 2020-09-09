defmodule BattleBox.Games.Marooned.LogicTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.Marooned.Logic
  import BattleBox.Games.Marooned.Helpers
  alias BattleBox.Games.Marooned.Error
  alias BattleBox.Game.Error.Timeout

  describe "opponent/1" do
    test "it gives the mortal enemy of a player" do
      assert Logic.opponent(2) == 1
      assert Logic.opponent(1) == 2
    end
  end

  describe "available_adjacent_locations_for_player/2/3" do
    test "you can see the adjacent locations of a position" do
      game = ~m/0 0 0
                0 1 0
                0 0 0/

      assert [[0, 0], [0, 1], [0, 2], [1, 0], [1, 2], [2, 0], [2, 1], [2, 2]] ==
               Logic.available_adjacent_locations_for_player(game, 1)
    end

    test "removed locations are not available" do
      game = ~m/x x x
                x 1 x
                x x x/

      assert [] == Logic.available_adjacent_locations_for_player(game, 1)
    end

    test "You can't move into another player" do
      game = ~m/x x x
                x 1 x
                x 2 x/

      assert [] == Logic.available_adjacent_locations_for_player(game, 1)
    end
  end

  describe "available_to_be_removed/1/2" do
    test "If there aren't any spaces to be removed it returns an empty list" do
      game = ~m/x x x
                x 1 x
                x 2 x/

      assert [] == Logic.available_to_be_removed(game)
    end

    test "It returns the spaces that can be removed" do
      game1 = ~m/x 0 x
                 0 1 0
                 x 2 x/

      assert [[0, 1], [1, 2], [2, 1]] == Logic.available_to_be_removed(game1)

      game2 = ~m/0 1 2/

      assert [[0, 0]] = Logic.available_to_be_removed(game2)
    end
  end

  describe "score" do
    test "A player's score is 0 if there is no squares to move to" do
      game = ~m/x x x
                x 1 x
                x 2 x/

      assert %{1 => 0, 2 => 0} == Logic.score(game)
    end

    test "A player's score is equal to the number of open adjacent squares" do
      game = ~m/0 0 0
                0 1 0
                0 2 0/

      assert %{1 => 7, 2 => 4} == Logic.score(game)
    end
  end

  describe "over?" do
    test "A game is over if the next player up can't move" do
      game1 = ~m/x x x
                 x 1 x
                 x 2 x/

      game2 = ~m/x x x
                 x 1 x
                 x x x/

      game3 = ~m/x 1 x
                 x x x
                 0 0 0/

      assert Logic.over?(game1)
      assert Logic.over?(game2)
      assert Logic.over?(game3)
    end

    test "The game is over if the only space that can be removed is one that the player can move to" do
      assert Logic.over?(~m/0 1 2/)
    end

    test "A game is not over if there is an opportunity for the next player to move" do
      game1 = ~m/x 0 x
                 x 1 x
                 x 0 x/

      game2 = ~m/0 1 x
                 x 0 x
                 0 x 0/

      refute Logic.over?(game1)
      refute Logic.over?(game2)
    end

    test "The game is not over if the next player can go even if the other player has lost" do
      game1 = ~m/0 1 0
                 x x x
                 x 2 x/

      refute Logic.over?(game1)
    end
  end

  describe "winner/1" do
    test "If the winner is explictly set, thats the winner" do
      game = ~m/0 0 0
                0 1 0
                0 0 0/

      game = Map.put(game, :winner, 1)
      assert Logic.winner(game) == 1
    end

    test "The game is only over if the next player can't move" do
      game = ~m/0 0 0
                0 1 0
                0 0 0/

      game = Map.put(game, :winner, 1)
      assert Logic.winner(game) == 1
    end
  end

  describe "player_positions/1/2" do
    test "It can give the player positions" do
      game1 = ~m/0 1 0
                 0 0 0
                 0 2 0/

      assert %{1 => [1, 2], 2 => [1, 0]} == Logic.player_positions(game1)

      game2 = ~m/0 1 2/

      assert %{1 => [1, 0], 2 => [2, 0]} == Logic.player_positions(game2)
    end
  end

  describe "calculate_turn/2" do
    test "timeouts yield the proper error" do
      start = ~m/0 1 2/
      assert %{debug: %{1 => [%Timeout{}]}} = Logic.calculate_turn(start, %{1 => :timeout})
    end

    for input <- [
          [],
          [1, 2],
          "foo",
          %{},
          %{"foo" => "bar"},
          %{"remove" => [1, 2]},
          %{"to" => [1, 2]},
          %{"remove" => [1, 2], "to" => "foo"}
        ] do
      test "the input #{inspect(input)} is improperly formatted and yields an error" do
        start = ~m/0 1 2/

        expected_error = %Error.InvalidInputFormat{input: unquote(Macro.escape(input))}

        %{debug: %{1 => error}} =
          Logic.calculate_turn(start, %{1 => unquote(Macro.escape(input))})

        assert expected_error in error
      end
    end

    test "You can't remove the space your opponent is on" do
      start = ~m/0 1 0
                 0 2 0/

      %{debug: %{1 => [%Error.CannotRemoveSpaceAPlayerIsOn{target: [1, 0]}]}} =
        Logic.calculate_turn(start, %{1 => %{"remove" => [1, 0], "to" => [0, 1]}})
    end

    test "You can't remove the space you're on" do
      start = ~m/0 1 0
                 0 2 0/

      %{debug: %{1 => [%Error.CannotRemoveSpaceAPlayerIsOn{target: [1, 1]}]}} =
        Logic.calculate_turn(start, %{1 => %{"remove" => [1, 1], "to" => [0, 1]}})
    end

    test "You can't remove an already removed space" do
      start = ~m/0 1 0
                 x 2 0/

      %{debug: %{1 => [%Error.CannotRemoveASpaceAlreadyRemoved{target: [0, 0]}]}} =
        Logic.calculate_turn(start, %{1 => %{"remove" => [0, 0], "to" => [0, 1]}})
    end

    test "you can't remove a square that is out of bounds" do
      start = ~m/0 1 0
                 0 2 0/

      for bad_square <- [[-1, 0], [0, -1], [0, 10], [10, 0]] do
        %{debug: %{1 => [%Error.CannotRemoveASpaceOutsideTheBoard{target: ^bad_square}]}} =
          Logic.calculate_turn(start, %{1 => %{"remove" => bad_square, "to" => [0, 1]}})
      end
    end

    test "you can't move to the same place you're removing" do
      start = ~m/0 1 0
                 0 0 0
                 0 2 0/

      %{debug: %{1 => [%Error.CannotRemoveSameSpaceAsMoveTo{target: [0, 0]}]}} =
        Logic.calculate_turn(start, %{1 => %{"remove" => [0, 0], "to" => [0, 0]}})
    end

    test "you can issue a valid move" do
      start = ~m/0 1 0
                 0 0 0
                 0 2 0/

      %{game: after_turn} =
        Logic.calculate_turn(start, %{1 => %{"remove" => [0, 0], "to" => [1, 1]}})

      expected = ~m/0 0 0
                    0 1 0
                    x 2 0/

      compare_games(after_turn, expected)
    end
  end

  defp compare_games(actual, expected) do
    import Logic

    assert player_positions(actual) == player_positions(expected)
    assert removed_locations(actual) == removed_locations(expected)
  end
end
