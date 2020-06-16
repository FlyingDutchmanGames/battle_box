defmodule BattleBox.GameEngine.MatchMaker.MatchMakerLogicTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Bot, Arena, Repo}
  import BattleBox.GameEngine.MatchMaker.MatchMakerLogic
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  setup do
    {:ok, user} = create_user()

    {:ok, bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "test-bot"})
      |> Repo.insert()

    {:ok, other_bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "something-else"})
      |> Repo.insert()

    {:ok, arena} = robot_game_arena(user: user, arena_name: "test-arena")

    %{bot: bot, other_bot: other_bot, arena: arena, user: user}
  end

  test "no players means no matches", %{arena: arena} do
    assert [] == make_matches([], arena.id)
  end

  test "one player means no matches", %{arena: arena, bot: bot} do
    player_1_pid = named_proxy(:player_1)
    matches = make_matches([%{bot: bot, pid: player_1_pid}], arena.id)
    assert [] = matches
  end

  test "it will chunk players by twos", %{arena: arena, bot: bot} do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    matches =
      make_matches([%{bot: bot, pid: player_1_pid}, %{bot: bot, pid: player_2_pid}], arena.id)

    assert [%{game: game, players: %{1 => pid1, 2 => pid2}}] = matches
    assert pid1 != pid2
    assert pid1 in [player_1_pid, player_2_pid]
    assert pid2 in [player_1_pid, player_2_pid]
  end

  test "it will only make one match if there are three in the queue", %{arena: arena, bot: bot} do
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
        arena.id
      )

    assert [%{game: game, players: %{1 => pid1, 2 => pid2}}] = matches
    assert pid1 != pid2
    assert pid1 in [player_1_pid, player_2_pid, player_3_pid]
    assert pid2 in [player_1_pid, player_2_pid, player_3_pid]
  end

  test "it will use the settings from the arena", %{arena: arena, bot: bot} do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    [%{game: game}] =
      make_matches([%{bot: bot, pid: player_1_pid}, %{bot: bot, pid: player_2_pid}], arena.id)

    from_arena = [
      :spawn_every,
      :spawn_per_player,
      :robot_hp,
      :max_turns,
      :attack_damage_min,
      :attack_damage_max,
      :collision_damage_min,
      :collision_damage_max,
      :suicide_damage_min,
      :suicide_damage_max,
      :terrain,
      :spawn_enabled
    ]

    assert Map.take(game.robot_game, from_arena) ==
             Map.take(Arena.get_settings(arena), from_arena)

    # It also preloads the user into the arena
    refute is_nil(game.arena.user.username)
  end

  test "the games it makes are persistable", %{arena: %{id: arena_id}, bot: bot} do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    [%{game: game}] =
      make_matches(
        [
          %{bot: bot, pid: player_1_pid},
          %{bot: bot, pid: player_2_pid}
        ],
        arena_id
      )

    {:ok, game} = Repo.insert(game)
    game = Repo.preload(game, [:game_bots])
    assert %{arena_id: arena_id} = game

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

  describe "user_self_play / bot_self_play settings" do
    test "when bot_self_play is false it won't match two of the same bots together", context do
      {:ok, _} =
        Arena.changeset(context.arena, %{bot_self_play: false})
        |> Repo.update()

      assert [] ==
               make_matches(
                 [%{bot: context.bot, pid: self()}, %{bot: context.bot, pid: self()}],
                 context.arena.id
               )
    end

    test "when bot_self_play is false, but user self play is true, different bots from the same user can play themselves",
         context do
      {:ok, _} =
        Arena.changeset(context.arena, %{user_self_play: true, bot_self_play: false})
        |> Repo.update()

      assert [%{game: _}] =
               make_matches(
                 [%{bot: context.bot, pid: self()}, %{bot: context.other_bot, pid: self()}],
                 context.arena.id
               )
    end

    test "when user_self_play is false it won't match two of the same users together", context do
      {:ok, _} =
        Arena.changeset(context.arena, %{user_self_play: false})
        |> Repo.update()

      assert [] ==
               make_matches(
                 [%{bot: context.bot, pid: self()}, %{bot: context.other_bot, pid: self()}],
                 context.arena.id
               )
    end
  end
end
