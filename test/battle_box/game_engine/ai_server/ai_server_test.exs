defmodule BattleBox.GameEngine.AiServerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Game, GameEngine, GameEngine.GameServer}
  alias BattleBox.Games.RobotGame

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    {:ok, arena} = robot_game_arena()

    game = %Game{
      id: Ecto.UUID.generate(),
      arena: arena,
      arena_id: arena.id,
      game_type: arena.game_type,
      game_bots: [],
      robot_game: %RobotGame{}
    }

    %{game: game}
  end

  test "you can start the thing", context do
    {:ok, ai_server} = GameEngine.start_ai(context.game_engine, %{logic: %{}})

    assert Process.alive?(ai_server)
  end

  test "it can accept a game", context do
    test_pid = self()

    {:ok, ai_server} =
      GameEngine.start_ai(context.game_engine, %{
        logic: %{
          initialize: fn _ -> send(test_pid, :got_game_request) end,
          commands: fn _ -> {:ok, :ok} end
        }
      })

    {:ok, _game_server} =
      GameEngine.start_game(context.game_engine, %{
        game: context.game,
        players: %{1 => self(), 2 => ai_server}
      })

    assert_receive {:game_request, %{player: player, game_server: game_server}}
    :ok = GameServer.accept_game(game_server, player)
    assert_receive :got_game_request
    assert_receive {:commands_request, _request}
  end
end
