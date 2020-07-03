defmodule BattleBox.Games.RobotGame.Ais.TheGuantletTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Game, GameEngine}
  alias BattleBox.Games.RobotGame

  setup do
    {:ok, arena} = robot_game_arena(command_time_minimum_ms: 0)

    game = %Game{
      id: Ecto.UUID.generate(),
      arena: arena,
      arena_id: arena.id,
      game_type: arena.game_type,
      game_bots: [],
      robot_game: %RobotGame{max_turns: 20}
    }

    %{game: game}
  end

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  for challenger_1 <- RobotGame.ais(), challenger_2 <- RobotGame.ais() do
    test "Robot Game: #{challenger_1.name} vs. #{challenger_2.name}", context do
      {:ok, ai_server1} =
        GameEngine.start_ai(context.game_engine, %{logic: unquote(challenger_1)})

      {:ok, ai_server2} =
        GameEngine.start_ai(context.game_engine, %{logic: unquote(challenger_2)})

      Process.monitor(ai_server1)
      Process.monitor(ai_server2)

      {:ok, game_server} =
        GameEngine.start_game(context.game_engine, %{
          game: context.game,
          players: %{1 => ai_server1, 2 => ai_server2}
        })

      Process.monitor(ai_server1)
      Process.monitor(ai_server2)
      Process.monitor(game_server)

      assert_receive {:DOWN, _ref, :process, ^ai_server1, :normal}, 200
      assert_receive {:DOWN, _ref, :process, ^ai_server2, :normal}
      assert_receive {:DOWN, _ref, :process, ^game_server, :normal}
    end
  end
end
