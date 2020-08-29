defmodule BattleBox.GameEngine.GameServerTest do
  alias BattleBox.{Game, GameEngine, GameEngine.GameServer}
  alias BattleBox.InstalledGames
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]
  use BattleBox.DataCase

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    {:ok, user} = create_user()
    %{user: user}
  end

  for game_type <- InstalledGames.installed_games() do
    describe "GameServer (with #{game_type.title}})" do
      setup do
        {:ok, user} = create_user()
        {:ok, arena} = create_arena(unquote(game_type), %{user: user, arena_name: "test-arena"})

        init_opts = %{
          players: %{
            1 => named_proxy(:player_1),
            2 => named_proxy(:player_2)
          },
          game: %Game{
            id: Ecto.UUID.generate(),
            arena: arena,
            arena_id: arena.id,
            game_bots: []
          }
        }

        init_opts =
          update_in(init_opts.game, fn game ->
            game.game_type
            |> put_in(unquote(game_type))
            |> Map.put(unquote(game_type).name, struct(unquote(game_type)))
          end)

        %{
          init_opts: init_opts,
          arena: arena
        }
      end

      test "you can start the game server", context do
        {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)
        assert Process.alive?(pid)
      end

      test "you can get the game from it", context do
        {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)
        {:ok, game} = GameServer.get_game(pid)
        assert game == context.init_opts.game
      end

      test "game servers emit a game start event", %{init_opts: %{game: %{id: id}}} = context do
        :ok =
          GameEngine.subscribe_to_arena_events(context.game_engine, context.arena.id, [
            :game_start
          ])

        {:ok, _pid} = GameEngine.start_game(context.game_engine, context.init_opts)
        assert_receive {{:arena, _}, :game_start, ^id}
      end

      test "the game server registers in the registry", context do
        assert Registry.count(context.game_registry) == 0
        {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)
        assert Registry.count(context.game_registry) == 1

        assert [{^pid, %{started_at: started_at, game: game}}] =
                 Registry.lookup(context.game_registry, context.init_opts.game.id)

        assert game == Game.metadata_only(context.init_opts.game)
        assert DateTime.diff(DateTime.utc_now(), started_at) < 2
      end

      test "the game server sends out game update messages", context do
        game_id = context.init_opts.game.id
        GameEngine.subscribe_to_game_events(context.game_engine, game_id, [:game_update])
        {:ok, _pid} = GameEngine.start_game(context.game_engine, context.init_opts)
        assert_receive {{:game, ^game_id}, :game_update, ^game_id}
      end

      test "if a player rejects the game both get a cancelled message", context do
        {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)

        ref = Process.monitor(pid)

        assert :ok = GameServer.accept_game(pid, 1)
        assert :ok = GameServer.reject_game(pid, 2)

        game_id = context.init_opts.game.id

        assert_receive {:player_1, {:game_cancelled, ^game_id}}
        assert_receive {:player_2, {:game_cancelled, ^game_id}}
        assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
      end

      test "if you die its the same as a forefit", context do
        Process.flag(:trap_exit, true)
        {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)

        :ok = GameServer.accept_game(pid, 1)
        :ok = GameServer.accept_game(pid, 2)

        player_2_pid = context.init_opts.players[2]

        Process.exit(player_2_pid, :kill)
        assert_receive {:EXIT, ^player_2_pid, :killed}

        assert_receive {:player_1, {:game_over, %{}}}
      end

      test "the starting of the game server will send init messages to p1 & p2", context do
        {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)
        game = context.init_opts.game

        expected = %{
          game_server: pid,
          game_id: game.id,
          accept_time: 2000,
          game_type: game.game_type.name,
          settings: Game.settings(game)
        }

        expected_p1 = {:player_1, {:game_request, Map.put(expected, :player, 1)}}
        expected_p2 = {:player_2, {:game_request, Map.put(expected, :player, 2)}}

        assert_receive ^expected_p1
        assert_receive ^expected_p2
      end

      test "if a player dies during game acceptance, the game is cancelled", context do
        {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)
        Process.flag(:trap_exit, true)

        game_ref = Process.monitor(pid)

        assert :ok = GameServer.accept_game(pid, 1)

        player_2_pid = context.init_opts.players[2]

        Process.exit(player_2_pid, :kill)
        assert_receive {:EXIT, ^player_2_pid, :killed}

        game_id = context.init_opts.game.id

        assert_receive {:player_1, {:game_cancelled, ^game_id}}
        assert_receive {:DOWN, ^game_ref, :process, ^pid, :normal}
      end

      test "when you accept a game it asks you for moves", context do
        {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)

        :ok = GameServer.accept_game(pid, 1)
        :ok = GameServer.accept_game(pid, 2)

        game_id = context.init_opts.game.id
        %{1 => p1_state, 2 => p2_state} = Game.commands_requests(context.init_opts.game)

        assert_receive {:player_1,
                        {:commands_request,
                         %{
                           game_id: ^game_id,
                           maximum_time: 1000,
                           minimum_time: 20,
                           game_state: ^p1_state,
                           player: 1
                         }}}

        assert_receive {:player_2,
                        {:commands_request,
                         %{
                           game_id: ^game_id,
                           maximum_time: 1000,
                           minimum_time: 20,
                           game_state: ^p2_state,
                           player: 2
                         }}}
      end

      test "if you forefit, you get a game over message/ the other player wins", context do
        {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)

        :ok = GameServer.accept_game(pid, 1)
        :ok = GameServer.accept_game(pid, 2)
        :ok = GameServer.forfeit_game(pid, 1)

        assert_receive {:player_1, {:game_over, %{}}}
        assert_receive {:player_2, {:game_over, %{}}}
      end

      test "you can play a game! (and it persists it to the db when you're done)", context do
        {:ok, pid} = GameEngine.start_game(context.game_engine, context.init_opts)

        ref = Process.monitor(pid)

        assert_receive {:player_1,
                        {:game_request, %{game_server: ^pid, player: 1, game_id: game_id}}}

        assert_receive {:player_2,
                        {:game_request, %{game_server: ^pid, player: 2, game_id: ^game_id}}}

        assert :ok = GameServer.accept_game(pid, 1)
        assert :ok = GameServer.accept_game(pid, 2)

        Stream.unfold([], fn game_overs ->
          receive do
            {:player_1, {:commands_request, %{}}} ->
              GameServer.submit_commands(pid, 1, :timeout)
              {:ok, game_overs}

            {:player_2, {:commands_request, %{}}} ->
              GameServer.submit_commands(pid, 2, :timeout)
              {:ok, game_overs}

            {player, {:game_over, %{game_id: ^game_id}}} when player in [:player_1, :player_2] ->
              nil
          after
            200 ->
              raise "Fail for taking toooo long"
          end
        end)
        |> Stream.run()

        assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

        loaded_game = Repo.get(Game, game_id)
        refute is_nil(loaded_game)
      end
    end
  end
end
