defmodule BattleBox.GameTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Game, Repo, Games.RobotGame}

  @lobby_id Ecto.UUID.generate()

  test "you can persist them" do
    assert {:ok, _bbg} =
             Repo.insert(%Game{
               lobby_id: @lobby_id,
               game_bots: []
             })
  end

  describe "persist/1" do
    test "you can persist a game with a robot game" do
      {:ok, _} = Game.persist(Game.new(robot_game: RobotGame.new()))
    end
  end

  test "new/1 creates one" do
    assert %Game{game_bots: [], lobby_id: nil} = Game.new()
    assert %Game{game_bots: [], lobby_id: @lobby_id} = Game.new(lobby_id: @lobby_id)
  end
end
