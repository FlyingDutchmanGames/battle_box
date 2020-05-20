defmodule BattleBox.GameEngine.MatchMakerServerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Bot, Lobby, GameEngine}
  alias BattleBox.GameEngine.{MatchMaker, MatchMakerServer}
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)

    names = GameEngine.names(name)

    true =
      names.match_maker_server
      |> Process.whereis()
      |> Process.link()

    {:ok, names}
  end

  setup do
    {:ok, user} = create_user()

    {:ok, bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "FOO"})
      |> Repo.insert()

    {:ok, lobby} =
      Lobby.create(%{
        name: "TEST LOBBY",
        game_type: "robot_game",
        user_id: Ecto.UUID.generate()
      })

    %{lobby: lobby, bot: bot}
  end

  test "you can start it", names do
    assert names.match_maker_server
           |> Process.whereis()
           |> Process.alive?()
  end

  test "it will match you up with someone", %{lobby: lobby, bot: bot} = names do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    :ok = MatchMaker.join_queue(names.game_engine, lobby.id, bot, player_1_pid)
    :ok = MatchMaker.join_queue(names.game_engine, lobby.id, bot, player_2_pid)
    :ok = MatchMakerServer.force_match_make(names.game_engine)

    assert_receive {:player_1,
                    {:game_request,
                     %{game_id: game_id, game_server: game_server, settings: settings}}}

    assert_receive {:player_2,
                    {:game_request,
                     %{game_id: ^game_id, game_server: ^game_server, settings: ^settings}}}
  end

  test "it will not match up two players in different lobbies",
       %{lobby: lobby, bot: bot} = names do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    {:ok, lobby2} =
      Lobby.create(%{
        name: "TEST LOBBY 2",
        game_type: "robot_game",
        user_id: Ecto.UUID.generate()
      })

    :ok = MatchMaker.join_queue(names.game_engine, lobby.id, bot, player_1_pid)
    :ok = MatchMaker.join_queue(names.game_engine, lobby2.id, bot, player_2_pid)
    :ok = MatchMakerServer.force_match_make(names.game_engine)

    refute_receive {_, {:game_request, _}}
  end
end
