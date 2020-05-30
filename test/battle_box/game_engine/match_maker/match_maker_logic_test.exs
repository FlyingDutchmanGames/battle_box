defmodule BattleBox.GameEngine.MatchMaker.MatchMakerLogicTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Bot, Lobby, Repo}
  import BattleBox.GameEngine.MatchMaker.MatchMakerLogic
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  setup do
    {:ok, user} = create_user()

    {:ok, bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "test-bot"})
      |> Repo.insert()

    {:ok, lobby} = robot_game_lobby(user: user, lobby_name: "test-lobby")

    %{bot: bot, lobby: lobby}
  end

  test "no players means no matches", %{lobby: lobby} do
    assert [] == make_matches([], lobby.id)
  end

  test "one player means no matches", %{lobby: lobby, bot: bot} do
    player_1_pid = named_proxy(:player_1)
    matches = make_matches([%{bot: bot, pid: player_1_pid}], lobby.id)
    assert [] = matches
  end

  test "it will chunk players by twos", %{lobby: lobby, bot: bot} do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    matches =
      make_matches([%{bot: bot, pid: player_1_pid}, %{bot: bot, pid: player_2_pid}], lobby.id)

    assert [%{game: game, players: %{1 => ^player_1_pid, 2 => ^player_2_pid}}] = matches
  end

  test "it will only make one match if there are three in the queue", %{lobby: lobby, bot: bot} do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)
    player_3_pid = named_proxy(:player_3)

    matches =
      make_matches(
        [
          %{bot: bot, pid: player_1_pid},
          %{bot: bot, pid: player_2_pid},
          %{bot: bot, pid: player_3_pid}
        ],
        lobby.id
      )

    assert [%{game: game, players: %{1 => ^player_1_pid, 2 => ^player_2_pid}}] = matches
  end

  test "it will use the settings from the lobby", %{lobby: lobby, bot: bot} do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    [%{game: game}] =
      make_matches([%{bot: bot, pid: player_1_pid}, %{bot: bot, pid: player_2_pid}], lobby.id)

    from_lobby = [
      :spawn_every,
      :spawn_per_player,
      :robot_hp,
      :max_turns,
      :attack_damage,
      :collision_damage,
      :suicide_damage,
      :terrain,
      :spawn_enabled
    ]

    assert Map.take(game.robot_game, from_lobby) ==
             Map.take(Lobby.get_settings(lobby), from_lobby)
  end

  test "the games it makes are persistable", %{lobby: %{id: lobby_id}, bot: bot} do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    [%{game: game}] =
      make_matches(
        [
          %{bot: bot, pid: player_1_pid},
          %{bot: bot, pid: player_2_pid}
        ],
        lobby_id
      )

    {:ok, game} = Repo.insert(game)
    game = Repo.preload(game, [:game_bots])
    assert %{lobby_id: lobby_id} = game

    assert [
             %{
               player: 1,
               bot: bot,
               score: 0
             },
             %{
               player: 2,
               bot: bot,
               score: 0
             }
           ] = game.game_bots
  end
end
