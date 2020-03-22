defmodule BattleBox.GameEngine.BotServerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{GameEngine, Repo, Bot, Lobby, Games.RobotGame}
  alias BattleBox.GameEngine.{MatchMaker, BotServer}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  @user_id Ecto.UUID.generate()
  @bot_1_server_id Ecto.UUID.generate()
  @bot_2_server_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    {:ok, bot} =
      Bot.create(%{
        user_id: @user_id,
        name: "BOT_NAME"
      })

    {:ok, lobby} =
      Lobby.create(%{
        user_id: @user_id,
        name: "LOBBY NAME",
        game_type: RobotGame,
        move_time_minimum_ms: 10
      })

    %{lobby: lobby, bot: bot}
  end

  setup %{lobby: lobby, bot: bot} do
    %{
      init_opts_p1: %{
        bot_server_id: @bot_1_server_id,
        bot: bot,
        lobby: lobby,
        connection: named_proxy(:p1_connection)
      },
      init_opts_p2: %{
        bot_server_id: @bot_2_server_id,
        bot: bot,
        lobby: lobby,
        connection: named_proxy(:p2_connection)
      }
    }
  end

  setup context do
    {:ok, p1_server, _} = GameEngine.start_bot(context.game_engine, context.init_opts_p1)
    {:ok, p2_server, _} = GameEngine.start_bot(context.game_engine, context.init_opts_p2)
    Process.monitor(p1_server)
    Process.monitor(p2_server)
    %{p1_server: p1_server, p2_server: p2_server}
  end

  test "you can start the bot server", context do
    assert Process.alive?(context.p1_server)
    assert Process.alive?(context.p2_server)
  end

  test "it publishes the bot server start event", context do
    id = Ecto.UUID.generate()
    GameEngine.subscribe_to_user_events(context.game_engine, @user_id, [:bot_server_start])

    {:ok, _, _} =
      GameEngine.start_bot(context.game_engine, %{context.init_opts_p1 | bot_server_id: id})

    assert_receive {:bot_server_start, ^id}
  end

  test "The bot server dies if the connection dies", %{p1_server: p1} = context do
    Process.flag(:trap_exit, true)
    p1_conn = context.init_opts_p1.connection
    Process.exit(p1_conn, :kill)
    assert_receive {:EXIT, ^p1_conn, :killed}
    assert_receive {:DOWN, _, _, ^p1, :normal}
  end

  test "the bot server registers in the bot server registry",
       %{p1_server: p1, p2_server: p2, bot: bot, lobby: lobby} = context do
    assert Registry.count(context.bot_registry) == 2

    assert [{^p1, %{bot: ^bot, lobby: ^lobby, game_id: nil}}] =
             Registry.lookup(context.bot_registry, context.init_opts_p1.bot_server_id)

    assert [{^p2, %{bot: ^bot, lobby: ^lobby, game_id: nil}}] =
             Registry.lookup(context.bot_registry, context.init_opts_p2.bot_server_id)
  end

  describe "Matchmaking in a lobby" do
    test "You can ask the bot server to match_make",
         %{p1_server: p1, bot: %{id: bot_id}} = context do
      assert [] == MatchMaker.queue_for_lobby(context.game_engine, context.lobby.id)

      :ok = BotServer.match_make(context.p1_server)

      assert [%{bot: %{id: ^bot_id}, pid: ^p1}] =
               MatchMaker.queue_for_lobby(context.game_engine, context.lobby.id)
    end

    test "When a match is made it forwards the request to the connections", context do
      :ok = BotServer.match_make(context.p1_server)
      :ok = BotServer.match_make(context.p2_server)
      :ok = GameEngine.force_match_make(context.game_engine)

      assert_receive {:p1_connection, {:game_request, %{game_id: game_id}}}
      assert_receive {:p2_connection, {:game_request, %{game_id: ^game_id}}}
    end
  end

  test "players reject game requests they're not expecting", context do
    game_id = Ecto.UUID.generate()
    game_server = named_proxy(:game_server)

    send(
      context.p1_server,
      {:game_request, %{game_id: game_id, game_server: game_server, player: 1}}
    )

    assert_receive {:game_server, {:"$gen_cast", {:reject_game, 1}}}
  end

  test "if you wait too long to accept, the game is cancelled", context do
    Lobby.changeset(context.lobby, %{game_acceptance_time_ms: 1})
    |> Repo.update!()

    :ok = BotServer.match_make(context.p1_server)
    :ok = BotServer.match_make(context.p2_server)
    :ok = GameEngine.force_match_make(context.game_engine)
    assert_receive {:p1_connection, {:game_request, %{game_id: game_id}}}
    assert_receive {:p2_connection, {:game_request, %{game_id: ^game_id}}}
    assert_receive {:p1_connection, {:game_cancelled, ^game_id}}
    assert_receive {:p2_connection, {:game_cancelled, ^game_id}}
  end

  test "Your moves aren't submitted until after the lobby.minimum_time", context do
    Lobby.changeset(context.lobby, %{move_time_minimum_ms: 30})
    |> Repo.update!()

    :ok = BotServer.match_make(context.p1_server)
    :ok = BotServer.match_make(context.p2_server)
    :ok = GameEngine.force_match_make(context.game_engine)
    assert_receive {:p1_connection, {:game_request, %{game_id: game_id}}}
    assert_receive {:p2_connection, {:game_request, %{game_id: ^game_id}}}
    assert :ok = BotServer.accept_game(context.p1_server, game_id)
    assert :ok = BotServer.accept_game(context.p2_server, game_id)
    assert_receive {:p1_connection, {:moves_request, %{request_id: id1}}}
    assert_receive {:p2_connection, {:moves_request, %{request_id: id2}}}
    :ok = BotServer.submit_moves(context.p1_server, id1, [])
    :ok = BotServer.submit_moves(context.p2_server, id2, [])
    # We don't get asked for more moves for at least 50 ms
    refute_receive {_, {:moves_request, %{}}}, 30
    # Then we get asked for moves
    assert_receive {:p1_connection, {:moves_request, %{}}}
    assert_receive {:p2_connection, {:moves_request, %{}}}
  end

  test "trying to accept or reject a game you're not currently watching yield :ok", context do
    assert :ok = BotServer.accept_game(context.p1_server, Ecto.UUID.generate())
    assert :ok = BotServer.reject_game(context.p1_server, Ecto.UUID.generate())
  end

  describe "game acceptance" do
    setup context do
      :ok = BotServer.match_make(context.p1_server)
      :ok = BotServer.match_make(context.p2_server)
      :ok = GameEngine.force_match_make(context.game_engine)
    end

    test "if you accept a game and it gets cancelled you go to matchmaking", context do
      assert_receive {:p1_connection, {:game_request, %{game_id: game_id}}}
      :ok = BotServer.accept_game(context.p1_server, game_id)
      :ok = BotServer.reject_game(context.p2_server, game_id)
      assert_receive {:p1_connection, {:game_cancelled, ^game_id}}
    end

    test "if the other player dies you get a game cancelled", context do
      Process.flag(:trap_exit, true)
      assert_receive {:p1_connection, {:game_request, %{game_id: game_id}}}
      :ok = BotServer.accept_game(context.p1_server, game_id)
      Process.exit(context.p2_server, :kill)
      assert_receive {:p1_connection, {:game_cancelled, ^game_id}}
    end

    test "if the game dies you both get a game cancelled", context do
      assert_receive {:p1_connection, {:game_request, %{game_id: game_id}}}
      [{game_server_pid, _}] = Registry.lookup(context.game_registry, game_id)
      Process.exit(game_server_pid, :kill)
      assert_receive {:p1_connection, {:game_cancelled, ^game_id}}
      assert_receive {:p2_connection, {:game_cancelled, ^game_id}}
    end

    test "you can accept a game", context do
      assert_receive {:p1_connection, {:game_request, %{game_id: game_id}}}
      assert_receive {:p2_connection, {:game_request, %{game_id: ^game_id}}}

      :ok = BotServer.accept_game(context.p1_server, game_id)
      :ok = BotServer.accept_game(context.p2_server, game_id)

      assert_receive {:p1_connection,
                      {:moves_request, %{game_id: ^game_id, maximum_time: max, minimum_time: min}}}

      assert_receive {:p2_connection,
                      {:moves_request,
                       %{game_id: ^game_id, maximum_time: ^max, minimum_time: ^min}}}

      assert [{_pid, %{game_id: ^game_id}}] =
               Registry.lookup(context.bot_registry, context.init_opts_p1.bot_server_id)
    end
  end

  describe "playing a game!" do
    setup context do
      :ok = BotServer.match_make(context.p1_server)
      :ok = BotServer.match_make(context.p2_server)
      :ok = GameEngine.force_match_make(context.game_engine)

      assert_receive {:p1_connection, {:game_request, %{game_id: game_id} = game_info}}

      :ok = BotServer.accept_game(context.p1_server, game_id)
      :ok = BotServer.accept_game(context.p2_server, game_id)
      %{game_id: game_id, game_info: game_info}
    end

    test "you can submit back a moves request", context do
      assert_receive {:p1_connection, {:moves_request, %{request_id: id}}}
      :ok = BotServer.submit_moves(context.p1_server, id, [])
    end

    test "trying to submit the wrong moves raises an error", context do
      assert_receive {:p1_connection, {:moves_request, _}}

      {:error, :invalid_moves_submission} =
        BotServer.submit_moves(context.p1_server, "INVALID", [])
    end

    test "game server dies => game cancelled notification", %{game_id: game_id} = context do
      # Bot 1 in the "playing" state after submitting his moves
      # Bot 2 in the moves input state, waiting on his moves
      assert_receive {:p1_connection, {:moves_request, %{request_id: id}}}
      :ok = BotServer.submit_moves(context.p1_server, id, [])

      [{game_server_pid, _}] = Registry.lookup(context.game_registry, context.game_id)
      Process.exit(game_server_pid, :kill)

      assert_receive {:p1_connection, {:game_cancelled, ^game_id}}
      assert_receive {:p2_connection, {:game_cancelled, ^game_id}}
    end

    test "other player dies => you get a game over notification", %{game_id: game_id} = context do
      Process.exit(context.p1_server, :kill)
      assert_receive {:p2_connection, {:game_over, %{game_id: ^game_id}}}
    end

    test "you can play a full game!!!!!", %{game_id: game_id} = context do
      Enum.each(0..(context.game_info.settings.max_turns - 1), fn turn ->
        assert_receive {:p1_connection,
                        {:moves_request, %{request_id: id, game_state: %{turn: ^turn}}}}

        :ok = BotServer.submit_moves(context.p1_server, id, [])

        assert_receive {:p2_connection,
                        {:moves_request, %{request_id: id, game_state: %{turn: ^turn}}}}

        :ok = BotServer.submit_moves(context.p2_server, id, [])
      end)

      assert_receive {:p1_connection, {:game_over, %{game_id: ^game_id}}}
      assert_receive {:p2_connection, {:game_over, %{game_id: ^game_id}}}
    end
  end
end
