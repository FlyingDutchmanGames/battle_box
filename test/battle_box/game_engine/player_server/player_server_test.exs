defmodule BattleBox.GameEngine.PlayerServerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{GameEngine, Repo, Lobby, Games.RobotGame}
  alias BattleBox.GameEngine.{MatchMaker, PlayerServer}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  @player_1_id Ecto.UUID.generate()
  @player_2_id Ecto.UUID.generate()

  @player_1_server_id Ecto.UUID.generate()
  @player_2_server_id Ecto.UUID.generate()

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    {:ok, lobby} =
      Lobby.create(%{user_id: @player_1_id, name: "LOBBY NAME", game_type: RobotGame})

    %{lobby: lobby}
  end

  setup %{lobby: %{name: lobby_name}} do
    %{
      init_opts_p1: %{
        player_id: @player_1_id,
        player_server_id: @player_1_server_id,
        lobby_name: lobby_name,
        connection: named_proxy(:p1_connection),
        connection_id: Ecto.UUID.generate()
      },
      init_opts_p2: %{
        player_id: @player_2_id,
        player_server_id: @player_2_server_id,
        lobby_name: lobby_name,
        connection: named_proxy(:p2_connection),
        connection_id: Ecto.UUID.generate()
      }
    }
  end

  setup context do
    {:ok, p1_server} = GameEngine.start_player(context.game_engine, context.init_opts_p1)
    {:ok, p2_server} = GameEngine.start_player(context.game_engine, context.init_opts_p2)
    Process.monitor(p1_server)
    Process.monitor(p2_server)
    %{p1_server: p1_server, p2_server: p2_server}
  end

  test "you can start the player server", context do
    assert Process.alive?(context.p1_server)
    assert Process.alive?(context.p2_server)
  end

  test "its an error to ask to join a lobby that doesn't exist", context do
    assert {:error, :lobby_not_found} =
             GameEngine.start_player(context.game_engine, %{
               context.init_opts_p1
               | lobby_name: "FAKE"
             })
  end

  test "The player server dies if the connection dies", %{p1_server: p1} = context do
    Process.flag(:trap_exit, true)
    p1_conn = context.init_opts_p1.connection
    Process.exit(p1_conn, :kill)
    assert_receive {:EXIT, ^p1_conn, :killed}
    assert_receive {:DOWN, _, _, ^p1, :normal}
  end

  test "the player server registers in the player server registry",
       %{p1_server: p1, p2_server: p2} = context do
    assert Registry.count(context.player_registry) == 2

    assert [{^p1, %{player_id: @player_1_id}}] =
             Registry.lookup(context.player_registry, context.init_opts_p1.player_server_id)

    assert [{^p2, %{player_id: @player_2_id}}] =
             Registry.lookup(context.player_registry, context.init_opts_p2.player_server_id)
  end

  describe "Matchmaking in a lobby" do
    test "You can ask the player server to match_make", %{p1_server: p1} = context do
      assert [] == MatchMaker.queue_for_lobby(context.game_engine, context.lobby.id)

      :ok = PlayerServer.match_make(context.p1_server)

      assert [%{player_id: @player_1_id, pid: ^p1}] =
               MatchMaker.queue_for_lobby(context.game_engine, context.lobby.id)
    end

    test "When a match is made it forwards the request to the connections", context do
      :ok = PlayerServer.match_make(context.p1_server)
      :ok = PlayerServer.match_make(context.p2_server)
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
      {:game_request, %{game_id: game_id, game_server: game_server, player: "player_1"}}
    )

    assert_receive {:game_server, {:"$gen_cast", {:reject_game, "player_1"}}}
  end

  test "if you wait too long to accept, the game is cancelled", context do
    Lobby.changeset(context.lobby, %{game_acceptance_timeout_ms: 1})
    |> Repo.update!()

    PlayerServer.reload_lobby(context.p1_server)
    PlayerServer.reload_lobby(context.p2_server)
    :ok = PlayerServer.match_make(context.p1_server)
    :ok = PlayerServer.match_make(context.p2_server)
    :ok = GameEngine.force_match_make(context.game_engine)
    assert_receive {:p1_connection, {:game_request, %{game_id: game_id, acceptance_time: 1}}}
    assert_receive {:p2_connection, {:game_request, %{game_id: ^game_id, acceptance_time: 1}}}
    assert_receive {:p1_connection, {:game_cancelled, ^game_id}}
    assert_receive {:p2_connection, {:game_cancelled, ^game_id}}
  end

  test "trying to accept or reject a game you're not currently watching yield :ok", context do
    assert :ok = PlayerServer.accept_game(context.p1_server, Ecto.UUID.generate())
    assert :ok = PlayerServer.reject_game(context.p1_server, Ecto.UUID.generate())
  end

  describe "game acceptance" do
    setup context do
      :ok = PlayerServer.match_make(context.p1_server)
      :ok = PlayerServer.match_make(context.p2_server)
      :ok = GameEngine.force_match_make(context.game_engine)
    end

    test "if you accept a game and it gets cancelled you go to matchmaking", context do
      assert_receive {:p1_connection, {:game_request, %{game_id: game_id}}}
      :ok = PlayerServer.accept_game(context.p1_server, game_id)
      :ok = PlayerServer.reject_game(context.p2_server, game_id)
      assert_receive {:p1_connection, {:game_cancelled, ^game_id}}
    end

    test "if the other player dies you get a game cancelled", context do
      Process.flag(:trap_exit, true)
      assert_receive {:p1_connection, {:game_request, %{game_id: game_id}}}
      :ok = PlayerServer.accept_game(context.p1_server, game_id)
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

      :ok = PlayerServer.accept_game(context.p1_server, game_id)
      :ok = PlayerServer.accept_game(context.p2_server, game_id)

      assert_receive {:p1_connection, {:moves_request, %{game_id: ^game_id, time: time}}}
      assert_receive {:p2_connection, {:moves_request, %{game_id: ^game_id, time: ^time}}}
    end
  end

  describe "playing a game!" do
    setup context do
      :ok = PlayerServer.match_make(context.p1_server)
      :ok = PlayerServer.match_make(context.p2_server)
      :ok = GameEngine.force_match_make(context.game_engine)

      assert_receive {:p1_connection, {:game_request, %{game_id: game_id} = game_info}}

      :ok = PlayerServer.accept_game(context.p1_server, game_id)
      :ok = PlayerServer.accept_game(context.p2_server, game_id)

      %{game_id: game_id, game_info: game_info}
    end

    test "you can submit back a moves request", context do
      assert_receive {:p1_connection, {:moves_request, %{request_id: id}}}
      :ok = PlayerServer.submit_moves(context.p1_server, id, [])
    end

    test "trying to submit the wrong moves raises an error", context do
      assert_receive {:p1_connection, {:moves_request, _}}

      {:error, :invalid_moves_submission} =
        PlayerServer.submit_moves(context.p1_server, "INVALID", [])
    end

    test "Moves timeouts submit blank moves and send an error to the connection" do
      # TODO:// not sure how to test this one yet, because the timeout comes from pretty deep in engine
      # eventually it should be derived from the lobby settings
    end

    test "game server dies => game cancelled notification", %{game_id: game_id} = context do
      # Player 1 in the "playing" state after submitting his moves
      # Player 2 in the moves input state, waiting on his moves
      assert_receive {:p1_connection, {:moves_request, %{request_id: id}}}
      :ok = PlayerServer.submit_moves(context.p1_server, id, [])

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

        :ok = PlayerServer.submit_moves(context.p1_server, id, [])

        assert_receive {:p2_connection,
                        {:moves_request, %{request_id: id, game_state: %{turn: ^turn}}}}

        :ok = PlayerServer.submit_moves(context.p2_server, id, [])
      end)

      assert_receive {:p1_connection, {:game_over, %{game_id: ^game_id}}}
      assert_receive {:p2_connection, {:game_over, %{game_id: ^game_id}}}
    end
  end
end
