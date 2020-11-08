defmodule BattleBox.GameEngine.BotServerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{GameEngine, GameEngine.BotServer, Repo, Arena}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]
  alias BattleBox.{InstalledGames, Games.AiOpponent}

  alias BattleBox.GameEngine.Message.{
    CommandsRequest,
    DebugInfo,
    GameInfo,
    GameOver,
    GameRequest,
    GameCanceled
  }

  @bot_1_server_id Ecto.UUID.generate()
  @bot_2_server_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  for game_type <- InstalledGames.installed_games() do
    describe "BotServer (with #{game_type.title()})" do
      setup %{game_engine: game_engine} do
        {:ok, user} = create_user()
        {:ok, bot} = create_bot(%{user: user})
        bot = Repo.preload(bot, :user)

        {:ok, arena} = create_arena(unquote(game_type))

        init_opts_p1 = %{
          bot_server_id: @bot_1_server_id,
          bot: bot,
          connection: named_proxy(:p1_connection)
        }

        init_opts_p2 = %{
          bot_server_id: @bot_2_server_id,
          bot: bot,
          connection: named_proxy(:p2_connection)
        }

        {:ok, p1_server, _} = GameEngine.start_bot(game_engine, init_opts_p1)
        {:ok, p2_server, _} = GameEngine.start_bot(game_engine, init_opts_p2)
        Process.monitor(p1_server)
        Process.monitor(p2_server)

        %{
          user: user,
          arena: arena,
          bot: bot,
          init_opts_p1: init_opts_p1,
          init_opts_p2: init_opts_p2,
          p1_server: p1_server,
          p2_server: p2_server
        }
      end

      test "you can start the bot server", context do
        assert Process.alive?(context.p1_server)
        assert Process.alive?(context.p2_server)
      end

      test "it publishes the bot server start event", %{user: %{id: user_id}} = context do
        id = Ecto.UUID.generate()

        GameEngine.subscribe_to_user_events(
          context.game_engine,
          user_id,
          [:bot_server_start]
        )

        {:ok, _, _} =
          GameEngine.start_bot(context.game_engine, %{context.init_opts_p1 | bot_server_id: id})

        assert_receive {{:user, ^user_id}, :bot_server_start, ^id}
      end

      test "The bot server dies if the connection dies", %{p1_server: p1} = context do
        Process.flag(:trap_exit, true)
        p1_conn = context.init_opts_p1.connection
        Process.exit(p1_conn, :kill)
        assert_receive {:EXIT, ^p1_conn, :killed}
        assert_receive {:DOWN, _, _, ^p1, :normal}
      end

      test "the bot server registers in the bot server registry",
           %{p1_server: p1, p2_server: p2, bot: bot} = context do
        assert Registry.count(context.bot_registry) == 2

        assert [{^p1, %{bot: ^bot, game_id: nil, started_at: %NaiveDateTime{}}}] =
                 Registry.lookup(context.bot_registry, context.init_opts_p1.bot_server_id)

        assert [{^p2, %{bot: ^bot, game_id: nil, started_at: %NaiveDateTime{}}}] =
                 Registry.lookup(context.bot_registry, context.init_opts_p2.bot_server_id)
      end

      test "the bot server broadcasts updates", context do
        id = context.init_opts_p1.bot_server_id

        GameEngine.subscribe_to_bot_server_events(
          context.game_engine,
          id,
          [:bot_server_update]
        )

        :ok = BotServer.match_make(context.p1_server, context.arena)

        assert_receive {{:bot_server, ^id}, :bot_server_update, ^id}
      end

      test "you can ask the bot server to practice", context do
        {:ok, [opponent | _]} = AiOpponent.opponent_modules(unquote(game_type))
        :ok = BotServer.practice(context.p1_server, context.arena, opponent.name)
        assert_receive {:p1_connection, %GameRequest{}}
      end

      test "asking for a nonsense opponent will give an error", context do
        {:error, :no_opponent_matching} =
          BotServer.practice(context.p1_server, context.arena, "nonsense")

        refute_receive {:p1_connection, %GameRequest{}}
      end

      test "you can ask the bot server to match_make",
           %{p1_server: p1, bot: %{id: bot_id}} = context do
        assert [] == GameEngine.queue_for_arena(context.game_engine, context.arena.id)

        :ok = BotServer.match_make(context.p1_server, context.arena)

        assert [%{bot: %{id: ^bot_id}, pid: ^p1}] =
                 GameEngine.queue_for_arena(context.game_engine, context.arena.id)
      end

      test "when a match is made it forwards the request to the connections", context do
        :ok = BotServer.match_make(context.p1_server, context.arena)
        :ok = BotServer.match_make(context.p2_server, context.arena)
        :ok = GameEngine.force_match_make(context.game_engine)

        assert_receive {:p1_connection, %GameRequest{game_id: game_id}}
        assert_receive {:p2_connection, %GameRequest{game_id: ^game_id}}
      end

      test "players reject game requests they're not expecting", context do
        game_id = Ecto.UUID.generate()
        game_server = named_proxy(:game_server)

        send(
          context.p1_server,
          %GameRequest{
            accept_time: 200,
            game_id: game_id,
            game_server: game_server,
            game_type: :foo,
            player: 1,
            settings: %{},
            players: %{},
            arena: %{}
          }
        )

        assert_receive {:game_server, {:"$gen_cast", {:reject_game, 1}}}
      end

      test "if you wait too long to accept, the game is cancelled", context do
        context.arena
        |> Arena.changeset()
        |> Ecto.Changeset.put_change(:game_acceptance_time_ms, 1)
        |> Repo.update!()

        :ok = BotServer.match_make(context.p1_server, context.arena)
        :ok = BotServer.match_make(context.p2_server, context.arena)
        :ok = GameEngine.force_match_make(context.game_engine)
        assert_receive {:p1_connection, %GameRequest{game_id: game_id}}
        assert_receive {:p2_connection, %GameRequest{game_id: ^game_id}}
        assert_receive {:p1_connection, %GameCanceled{game_id: ^game_id}}
        assert_receive {:p2_connection, %GameCanceled{game_id: ^game_id}}
      end

      test "Your commands aren't submitted until after the arena.minimum_time", context do
        context.arena
        |> Arena.changeset()
        |> Ecto.Changeset.put_change(:command_time_minimum_ms, 30)
        |> Repo.update!()

        :ok = BotServer.match_make(context.p1_server, context.arena)
        :ok = BotServer.match_make(context.p2_server, context.arena)
        :ok = GameEngine.force_match_make(context.game_engine)
        assert_receive {:p1_connection, %GameRequest{game_id: game_id}}
        assert_receive {:p2_connection, %GameRequest{game_id: ^game_id}}
        assert :ok = BotServer.accept_game(context.p1_server, game_id)
        assert :ok = BotServer.accept_game(context.p2_server, game_id)

        commands_requests =
          Stream.unfold(:unused, fn _ ->
            receive do
              {connection, %CommandsRequest{request_id: id, game_state: %{turn: 0}}} ->
                server =
                  %{p1_connection: context.p1_server, p2_connection: context.p2_server}[
                    connection
                  ]

                :ok = BotServer.submit_commands(server, id, [])
                {connection, :ok}

              {_connection, %CommandsRequest{game_state: %{turn: 1}}} ->
                raise "Recieved turn 1 commands request too soon!"
            after
              30 ->
                nil
            end
          end)
          |> Enum.into([])

        assert length(commands_requests) >= 1
        assert_receive {_connection, %CommandsRequest{game_state: %{turn: 1}}}
      end

      test "trying to accept or reject a game you're not currently watching yield :ok", context do
        assert :ok = BotServer.accept_game(context.p1_server, Ecto.UUID.generate())
        assert :ok = BotServer.reject_game(context.p1_server, Ecto.UUID.generate())
      end

      test "if you accept a game and it gets cancelled you go to matchmaking", context do
        :ok = match_make(context)
        assert_receive {:p1_connection, %GameRequest{game_id: game_id}}
        :ok = BotServer.accept_game(context.p1_server, game_id)
        :ok = BotServer.reject_game(context.p2_server, game_id)
        assert_receive {:p1_connection, %GameCanceled{game_id: ^game_id}}
      end

      test "if the other player dies you get a game cancelled", context do
        :ok = match_make(context)
        Process.flag(:trap_exit, true)
        assert_receive {:p1_connection, %GameRequest{game_id: game_id}}
        :ok = BotServer.accept_game(context.p1_server, game_id)
        Process.exit(context.p2_server, :kill)
        assert_receive {:p1_connection, %GameCanceled{game_id: ^game_id}}
      end

      test "if the game dies you both get a game cancelled", context do
        :ok = match_make(context)
        assert_receive {:p1_connection, %GameRequest{game_id: game_id}}
        [{game_server_pid, _}] = Registry.lookup(context.game_registry, game_id)
        Process.exit(game_server_pid, :kill)
        assert_receive {:p1_connection, %GameCanceled{game_id: ^game_id}}
        assert_receive {:p2_connection, %GameCanceled{game_id: ^game_id}}
      end

      test "you can accept a game", context do
        :ok = match_make(context)
        assert_receive {:p1_connection, %GameRequest{game_id: game_id}}
        assert_receive {:p2_connection, %GameRequest{game_id: ^game_id}}

        :ok = BotServer.accept_game(context.p1_server, game_id)
        :ok = BotServer.accept_game(context.p2_server, game_id)

        assert_receive {_connection_id,
                        %CommandsRequest{
                          game_id: ^game_id,
                          maximum_time: _max,
                          minimum_time: _min
                        }}

        assert [{_pid, %{game_id: ^game_id}}] =
                 Registry.lookup(context.bot_registry, context.init_opts_p1.bot_server_id)
      end

      test "you can submit back a commands request", context do
        {:ok, _} = accept_game(context)
        assert_receive {proxy_id, %CommandsRequest{request_id: id}}
        server = %{p1_connection: context.p1_server, p2_connection: context.p2_server}[proxy_id]
        :ok = BotServer.submit_commands(server, id, [])
      end

      test "You can get debug info", context do
        {:ok, %{game_id: game_id}} = accept_game(context)
        assert_receive {proxy_id, %CommandsRequest{request_id: id}}
        server = %{p1_connection: context.p1_server, p2_connection: context.p2_server}[proxy_id]
        :ok = BotServer.submit_commands(server, id, "something that's invalid")
        assert_receive {^proxy_id, %DebugInfo{debug_info: %{}, game_id: ^game_id}}
      end

      test "You can get game info", context do
        {:ok, %{game_id: game_id}} = accept_game(context)
        assert_receive {proxy_id, %CommandsRequest{request_id: id}}
        server = %{p1_connection: context.p1_server, p2_connection: context.p2_server}[proxy_id]
        :ok = BotServer.submit_commands(server, id, "something that's invalid")
        assert_receive {^proxy_id, %GameInfo{game_id: ^game_id, game_info: %{}}}
      end

      test "trying to submit the wrong commands raises an error", context do
        {:ok, _} = accept_game(context)
        assert_receive {proxy_id, %CommandsRequest{}}
        server = %{p1_connection: context.p1_server, p2_connection: context.p2_server}[proxy_id]

        {:error, :invalid_commands_submission} = BotServer.submit_commands(server, "INVALID", [])
      end

      test "game server dies => game cancelled notification", context do
        {:ok, %{game_id: game_id}} = accept_game(context)
        # Bot 1 in the "playing" state after submitting his commands
        # Bot 2 in the commands input state, waiting on his commands
        %{p1_server: p1_server} = context
        assert_receive {proxy_id, %CommandsRequest{request_id: id, player: 1}}
        server = %{p1_connection: context.p1_server, p2_connection: context.p2_server}[proxy_id]
        :ok = BotServer.submit_commands(server, id, [])

        [{game_server_pid, _}] = Registry.lookup(context.game_registry, game_id)
        Process.exit(game_server_pid, :kill)

        assert_receive {:p1_connection, %GameCanceled{game_id: ^game_id}}
        assert_receive {:p2_connection, %GameCanceled{game_id: ^game_id}}
        refute_receive {:DOWN, _ref, :process, ^p1_server, _}
      end

      test "other player dies => you get a game over notification", context do
        {:ok, %{game_id: game_id}} = accept_game(context)
        Process.exit(context.p1_server, :kill)
        assert_receive {:p2_connection, %GameOver{game_id: ^game_id}}
      end

      test "you can play a full game!!!!!", context do
        {:ok, %{game_id: game_id, game_info: %{game_server: game_server}}} = accept_game(context)

        Process.monitor(game_server)

        Stream.unfold(:unused, fn _ ->
          receive do
            {connection, %CommandsRequest{request_id: id, game_state: %{turn: turn}}} ->
              :ok =
                %{p1_connection: context.p1_server, p2_connection: context.p2_server}[connection]
                |> BotServer.submit_commands(id, [])

              {:ok, turn}

            {connection, %GameOver{game_id: ^game_id}}
            when connection in [:p1_connection, :p2_connection] ->
              nil
          after
            200 ->
              raise "Took tooooo long"
          end
        end)
        |> Stream.run()

        assert_receive {:DOWN, _ref, :process, ^game_server, :normal}
      end
    end
  end

  defp accept_game(context) do
    :ok = match_make(context)
    assert_receive {:p1_connection, %GameRequest{game_id: game_id} = game_info}

    :ok = BotServer.accept_game(context.p1_server, game_id)
    :ok = BotServer.accept_game(context.p2_server, game_id)
    {:ok, %{game_id: game_id, game_info: game_info}}
  end

  defp match_make(context) do
    :ok = BotServer.match_make(context.p1_server, context.arena)
    :ok = BotServer.match_make(context.p2_server, context.arena)
    :ok = GameEngine.force_match_make(context.game_engine)
  end
end
