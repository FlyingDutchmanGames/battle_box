defmodule BattleBox.Games.Marooned.LogicTest do
  use ExUnit.Case, async: true
  alias BattleBox.Games.Marooned.Logic
  import BattleBox.Games.Marooned.Helpers

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
      game = ~m/x 0 x
                0 1 0
                x 2 x/

      assert [[0, 1], [1, 2], [2, 1]] == Logic.available_to_be_removed(game)
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

    test "A game is not over if there is an opportunity to move" do
      game1 = ~m/x x x
                 x 1 x
                 x 0 x/

      game2 = ~m/x 1 x
                 x 0 x
                 0 0 0/

      refute Logic.over?(game1)
      refute Logic.over?(game2)
    end
  end

  describe "player_positions/1/2" do
    test "It can give the player positions" do
      game = ~m/0 1 0
                0 0 0
                0 2 0/

      assert %{1 => [1, 2], 2 => [1, 0]} == Logic.player_positions(game)
    end
  end

  describe "calculate_turn/2" do
    test "you can issue a valid move" do
      game = ~m/0 1 0
                0 0 0
                0 2 0/

      assert game.turn == 0
      assert %{1 => [1, 2], 2 => [1, 0]} = Logic.player_positions(game)
      assert [] = Logic.removed_locations(game)

      game = Logic.calculate_turn(game, %{1 => %{"remove" => [0, 0], "move_to" => [1, 1]}})

      assert game.turn == 1
      assert %{1 => [1, 1], 2 => [1, 0]} = Logic.player_positions(game)
      assert [[0, 0]] = Logic.removed_locations(game)
    end
  end
end
