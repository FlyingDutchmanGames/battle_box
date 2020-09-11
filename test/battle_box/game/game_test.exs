defmodule BattleBox.GameTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Game, Repo}

  @arena_id Ecto.UUID.generate()

  test "you can persist them" do
    assert {:ok, _game} =
             %Game{game_type: BattleBox.Games.Marooned, arena_id: @arena_id, game_bots: []}
             |> Repo.insert()
  end

  describe "preload_game_data" do
    test "with nil, yields nil" do
      assert Game.preload_game_data(nil) == nil
    end
  end

  describe "build" do
    setup do
      {:ok, arena} = marooned_arena()
      {:ok, bot1} = create_bot(bot_name: "bot-1")
      {:ok, bot2} = create_bot(bot_name: "bot-2")
      %{arena: arena, bot1: bot1, bot2: bot2}
    end

    test "you can build a game from an arena and some bots", %{
      arena: arena,
      bot1: bot1,
      bot2: bot2
    } do
      game = Game.build(arena, %{1 => bot1, 2 => bot2})
      assert game.game_type == arena.game_type
      assert game.arena_id == arena.id

      assert for(%{player: player, bot: bot} <- game.game_bots, do: {player, bot.id}) == [
               {1, bot1.id},
               {2, bot2.id}
             ]

      assert Game.game_data(game).__struct__ == arena.game_type
    end
  end
end
