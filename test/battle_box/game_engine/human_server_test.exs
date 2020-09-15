defmodule BattleBox.GameEngine.HumanServerTest do
  use ExUnit.Case, async: true
  use BattleBox.DataCase, async: false
  alias BattleBox.{Game, GameEngine, Games.Marooned}
  alias BattleBox.GameEngine.{GameServer, HumanServer}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1, named_proxy: 2]

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
    opts = %{}

    {:ok, human_server, %{human_server_id: id}} =
      GameEngine.start_human(context.game_engine, opts)

    assert Process.alive?(human_server)

    assert %{human_server_id: ^id, pid: ^human_server} =
             GameEngine.get_human_server(context.game_engine, id)
  end

  test "it can accept a game", context do
    {:ok, human_server, %{human_server_id: human_server_id}} =
      GameEngine.start_human(context.game_engine, %{})

    {:ok, _game_server} =
      GameEngine.start_game(context.game_engine, %{
        game: context.game,
        players: %{1 => named_proxy(:other_player), 2 => human_server}
      })

    assert_receive {:other_player,
                    {:game_request, %{player: player, game_server: game_server, game_id: game_id}}}

    :ok = GameServer.accept_game(game_server, player)
    Process.sleep(10)

    assert %{game_id: ^game_id} =
             GameEngine.get_human_server(context.game_engine, human_server_id)
  end

  test "if the game gets cancelled the human server dies", context do
    {:ok, human_server, _meta} =
      GameEngine.start_human(context.game_engine, %{ui_pid: named_proxy(:ui_pid)})

    {:ok, _game_server} =
      GameEngine.start_game(context.game_engine, %{
        game: context.game,
        players: %{1 => named_proxy(:other_player), 2 => human_server}
      })

    Process.monitor(human_server)

    assert_receive {:other_player,
                    {:game_request, %{player: player, game_server: game_server, game_id: game_id}}}

    :ok = GameServer.reject_game(game_server, player)
    Process.sleep(10)
    assert_receive {:DOWN, _ref, :process, ^human_server, :normal}
    assert_receive {:ui_pid, {:game_cancelled, ^game_id}}
  end

  test "if the game server crashes, the human server dies", context do
    {:ok, human_server, _meta} = GameEngine.start_human(context.game_engine, %{})

    {:ok, game_server} =
      GameEngine.start_game(context.game_engine, %{
        game: context.game,
        players: %{1 => named_proxy(:other_player), 2 => human_server}
      })

    Process.monitor(human_server)
    Process.sleep(10)
    Process.exit(game_server, :kill)
    assert_receive {:DOWN, _ref, :process, ^human_server, :normal}
  end

  describe "connect_ui/2" do
    test "you cannot connect when there is already a connection", context do
      {:ok, human_server, _mta} =
        GameEngine.start_human(context.game_engine, %{ui_pid: named_proxy(:ui_pid)})

      assert {:error, :already_connected} =
               HumanServer.connect_ui(human_server, named_proxy(:nope))
    end

    test "you can connect a ui pid when there is not one connected", context do
      {:ok, human_server, _meta} = GameEngine.start_human(context.game_engine, %{})

      {:ok, _game_server} =
        GameEngine.start_game(context.game_engine, %{
          game: context.game,
          players: %{1 => named_proxy(:other_player), 2 => human_server}
        })

      Process.sleep(10)

      assert {:ok, %{game_request: _, commands_request: _}} =
               HumanServer.connect_ui(human_server, named_proxy(:ui_pid))
    end

    test "You cannot connect a ui server until after the game request has arrived", context do
      test_pid = self()
      {:ok, human_server, _meta} = GameEngine.start_human(context.game_engine, %{})

      named_proxy(:ui_pid, fn ->
        assert {:ok, %{game_request: gr, commands_request: _}} =
                 HumanServer.connect_ui(human_server, named_proxy(:ui_pid))

        assert gr != nil
        send(test_pid, :success)
      end)

      refute_receive :success, 100

      {:ok, _game_server} =
        GameEngine.start_game(context.game_engine, %{
          game: context.game,
          players: %{1 => named_proxy(:other_player), 2 => human_server}
        })

      assert_receive :success
    end

    test "if a connection dies, you can reconnect and get the current game state", context do
      {:ok, human_server, _meta} = GameEngine.start_human(context.game_engine, %{})

      {:ok, _game_server} =
        GameEngine.start_game(context.game_engine, %{
          game: context.game,
          players: %{1 => named_proxy(:other_player), 2 => human_server}
        })

      pid_to_kill = named_proxy(:pid_to_kill)

      assert {:ok, %{game_request: gr, commands_request: cr}} =
               HumanServer.connect_ui(human_server, pid_to_kill)

      Process.flag(:trap_exit, true)
      Process.exit(pid_to_kill, :kill)
      Process.sleep(10)

      assert {:ok, %{game_request: ^gr, commands_request: ^cr}} =
               HumanServer.connect_ui(human_server, named_proxy(:some_other_process))

      assert {:error, :already_connected} =
               HumanServer.connect_ui(human_server, named_proxy(:nope))
    end
  end

  describe "submit_commands/2" do
    test "The human server will ask the UI server for commands", context do
      {:ok, human_server, _meta} =
        GameEngine.start_human(context.game_engine, %{ui_pid: named_proxy(:ui_pid)})

      {:ok, game_server} =
        GameEngine.start_game(context.game_engine, %{
          game: context.game,
          players: %{1 => named_proxy(:other_player), 2 => human_server}
        })

      assert_receive {:other_player, {:game_request, %{player: player, game_id: game_id}}}

      :ok = GameServer.accept_game(game_server, player)

      assert_receive {:other_player, {:commands_request, %{player: player}}}
      GameServer.submit_commands(game_server, player, %{})

      assert_receive {:ui_pid, {:commands_request, commands_request}}
      assert %{game_state: _, player: _} = commands_request
    end

    test "if the ui process crashes, it will ask for the same commands of the new connection",
         context do
      ui_pid = named_proxy(:ui_pid)

      {:ok, human_server, _meta} = GameEngine.start_human(context.game_engine, %{ui_pid: ui_pid})

      {:ok, game_server} =
        GameEngine.start_game(context.game_engine, %{
          game: context.game,
          players: %{2 => named_proxy(:other_player), 1 => human_server}
        })

      assert_receive {:other_player, {:game_request, %{player: player, game_id: game_id}}}

      :ok = GameServer.accept_game(game_server, player)
      Process.sleep(10)
      Process.monitor(ui_pid)

      assert_receive {:ui_pid, {:commands_request, commands_request}}
      Process.flag(:trap_exit, true)
      Process.exit(ui_pid, :kill)
      assert_receive {:DOWN, _, :process, ^ui_pid, _}
      Process.sleep(10)

      assert {:ok, %{commands_request: ^commands_request}} =
               HumanServer.connect_ui(human_server, self())

      assert {:error, :already_connected} =
               HumanServer.connect_ui(human_server, named_proxy(:nope))
    end
  end

  test "playing a full game", context do
    {:ok, human_server, _meta} =
      GameEngine.start_human(context.game_engine, %{ui_pid: named_proxy(:ui_pid)})

    {:ok, game_server} =
      GameEngine.start_game(context.game_engine, %{
        game: context.game,
        players: %{1 => named_proxy(:other_player), 2 => human_server}
      })

    Process.monitor(human_server)

    assert_receive {:other_player, {:game_request, %{player: player, game_id: game_id}}}

    :ok = GameServer.accept_game(game_server, player)

    Stream.unfold(nil, fn _ ->
      receive do
        {:other_player, {:commands_request, %{player: player}}} ->
          GameServer.submit_commands(game_server, player, %{})
          {:ok, :ok}

        {:ui_pid, {:commands_request, _commands_request}} ->
          HumanServer.submit_commands(human_server, %{})
          {:ok, :ok}

        {:ui_pid, {:game_over, %{game_id: _game_id, score: %{1 => _, 2 => _}}}} ->
          nil
      after
        100 ->
          flunk("Didn't get messages fast enough")
      end
    end)
    |> Stream.run()

    assert_receive {:DOWN, _, :process, ^human_server, :normal}
  end

  describe "inactivity timeouts" do
    test "if no one connects before the connection_timeout, the human server dies", context do
      {:ok, human_server, _meta} =
        GameEngine.start_human(context.game_engine, %{connection_timeout: 2})

      Process.monitor(human_server)
      assert_receive {:DOWN, _, :process, ^human_server, :normal}
    end

    test "if someone connects and then disconnects, the server dies after connection_timeout",
         context do
      pid_to_kill = named_proxy(:foo)

      {:ok, human_server, _meta} =
        GameEngine.start_human(context.game_engine, %{connection_timeout: 2, ui_pid: pid_to_kill})

      Process.flag(:trap_exit, true)
      Process.monitor(human_server)
      refute_receive {:DOWN, _, :process, ^human_server, :normal}, 100

      Process.exit(pid_to_kill, :kill)
      assert_receive {:DOWN, _, :process, ^human_server, :normal}
    end

    test "if a new process connects fast enough, the server doesn't die", context do
      pid_to_kill = named_proxy(:foo)

      {:ok, human_server, _meta} =
        GameEngine.start_human(context.game_engine, %{connection_timeout: 10, ui_pid: pid_to_kill})

      GameEngine.start_game(context.game_engine, %{
        game: context.game,
        players: %{1 => named_proxy(:other_player), 2 => human_server}
      })

      Process.flag(:trap_exit, true)
      Process.monitor(human_server)
      Process.exit(pid_to_kill, :kill)
      Process.sleep(5)

      {:ok, _} = HumanServer.connect_ui(human_server, self())
      refute_receive {:DOWN, _, :process, ^human_server, :normal}, 50
    end
  end
end
