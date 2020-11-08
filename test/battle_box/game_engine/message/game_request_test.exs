defmodule BattleBox.GameEngine.Message.GameRequestTest do
  use BattleBox.DataCase, async: true

  alias BattleBox.GameEngine.Message.GameRequest
  alias BattleBox.{Game, Repo}

  describe "new/3" do
    test "you can create a game request" do
      {:ok, bot} = create_bot()
      bot = Repo.preload(bot, :user)
      {:ok, arena} = marooned_arena()
      game = Game.build(arena, %{1 => bot, 2 => bot})

      assert %BattleBox.GameEngine.Message.GameRequest{
               accept_time: arena.game_acceptance_time_ms,
               arena: %{name: arena.name},
               game_id: game.id,
               game_server: self(),
               game_type: :marooned,
               player: 1,
               players: %{
                 1 => %{
                   bot: %{
                     name: bot.name,
                     user: %{
                       avatar_url: bot.user.avatar_url,
                       username: bot.user.username
                     }
                   }
                 },
                 2 => %{
                   bot: %{
                     name: bot.name,
                     user: %{
                       avatar_url: bot.user.avatar_url,
                       username: bot.user.username
                     }
                   }
                 }
               },
               settings: %{cols: 10, rows: 10}
             } == GameRequest.new(self(), 1, game)
    end
  end
end
