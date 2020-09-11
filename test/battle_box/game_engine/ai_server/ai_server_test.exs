defmodule BattleBox.GameEngine.AiServerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Game, GameEngine, GameEngine.GameServer}
  alias BattleBox.Games.Marooned

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    {:ok, arena} = marooned_arena()

    game = %Game{
      id: Ecto.UUID.generate(),
      arena: arena,
      arena_id: arena.id,
      game_type: arena.game_type,
      game_bots: [],
      marooned: %Marooned{}
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

  test "if the game dies, the ai server dies", context do
    {:ok, ai_server} =
      GameEngine.start_ai(context.game_engine, %{
        logic: %{initialize: fn _ -> :ok end, commands: fn _ -> {:ok, :ok} end}
      })

    Process.monitor(ai_server)

    {:ok, game_server} =
      GameEngine.start_game(context.game_engine, %{
        game: context.game,
        players: %{1 => self(), 2 => ai_server}
      })

    assert Process.alive?(ai_server)
    Process.sleep(10)
    Process.exit(game_server, :kill)
    assert_receive {:DOWN, _ref, :process, ^ai_server, :normal}
  end

  test "if the game is cancelled the ai server dies", context do
    {:ok, ai_server} =
      GameEngine.start_ai(context.game_engine, %{
        logic: %{initialize: fn _ -> :ok end, commands: fn _ -> {:ok, :ok} end}
      })

    Process.monitor(ai_server)

    {:ok, game_server} =
      GameEngine.start_game(context.game_engine, %{
        game: context.game,
        players: %{1 => self(), 2 => ai_server}
      })

    assert Process.alive?(ai_server)
    Process.sleep(10)
    GameServer.reject_game(game_server, 1)
    assert_receive {:DOWN, _ref, :process, ^ai_server, :normal}
  end

  test "it can play a full game!", context do
    test_pid = self()

    {:ok, ai_server1} =
      GameEngine.start_ai(context.game_engine, %{
        logic: %{
          initialize: fn _ -> send(test_pid, :got_game_request) end,
          commands: fn commands_request ->
            send(test_pid, {1, :got_commands_request, commands_request.game_state.turn})
            {[], :ok}
          end
        }
      })

    {:ok, ai_server2} =
      GameEngine.start_ai(context.game_engine, %{
        logic: %{
          initialize: fn _ -> send(test_pid, :got_game_request) end,
          commands: fn commands_request ->
            send(test_pid, {2, :got_commands_request, commands_request.game_state.turn})
            {[], :ok}
          end
        }
      })

    Process.monitor(ai_server1)
    Process.monitor(ai_server2)

    {:ok, _game_server} =
      GameEngine.start_game(context.game_engine, %{
        game: context.game,
        players: %{1 => ai_server2, 2 => ai_server1}
      })

    turns =
      Stream.unfold(:ok, fn _ ->
        receive do
          {_player, :got_commands_request, turn} ->
            {turn, :ok}
        after
          200 ->
            nil
        end
      end)
      |> Enum.to_list()

    assert length(turns) > 2
    assert_receive {:DOWN, _ref, :process, ^ai_server1, :normal}
    assert_receive {:DOWN, _ref, :process, ^ai_server2, :normal}
  end
end
