defmodule BattleBox.GameEngine.MatchMaker.MatchMakerLogicTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Bot, Arena, User}
  alias BattleBox.Games.{Marooned, Marooned.Settings}
  import BattleBox.GameEngine.MatchMaker.MatchMakerLogic
  import BattleBox.TestConvenienceHelpers, only: [named_proxy: 1]

  setup do
    user = %User{
      username: "user-username",
      id: Ecto.UUID.generate()
    }

    arena = %Arena{
      name: "test-arena",
      id: Ecto.UUID.generate(),
      user: user,
      user_id: user.id,
      game_type: Marooned,
      marooned_settings: %Settings{}
    }

    bot = %Bot{
      name: "test-bot",
      id: Ecto.UUID.generate(),
      user: user,
      user_id: user.id
    }

    other_bot = %Bot{
      name: "other-bot",
      id: Ecto.UUID.generate(),
      user: user,
      user_id: user.id
    }

    %{
      user: user,
      arena: arena,
      bot: bot,
      other_bot: other_bot
    }
  end

  test "no players means no matches", %{arena: arena} do
    assert [] == make_matches([], arena)
  end

  test "one player means no matches", %{arena: arena, bot: bot} do
    matches = make_matches([%{bot: bot, pid: self()}], arena)
    assert [] = matches
  end

  test "it will chunk players by twos", %{arena: arena, bot: bot} do
    player_1_pid = named_proxy(:player_1)
    player_2_pid = named_proxy(:player_2)

    matches =
      make_matches([%{bot: bot, pid: player_1_pid}, %{bot: bot, pid: player_2_pid}], arena)

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
        arena
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
      make_matches([%{bot: bot, pid: player_1_pid}, %{bot: bot, pid: player_2_pid}], arena)

    from_arena = [
      :spawn_every,
      :spawn_per_player,
      :robot_hp,
      :max_turns,
      :attack_damage_min,
      :attack_damage_max,
      :collision_damage_min,
      :collision_damage_max,
      :explode_damage_min,
      :explode_damage_max,
      :terrain,
      :spawn_enabled
    ]

    assert Map.take(game.robot_game, from_arena) ==
             Map.take(Arena.get_settings(arena), from_arena)
  end

  describe "user_self_play / bot_self_play settings" do
    test "when bot_self_play is false it won't match two of the same bots together", context do
      context = update_in(context.arena, &Map.put(&1, :bot_self_play, false))

      assert [] ==
               make_matches(
                 [%{bot: context.bot, pid: self()}, %{bot: context.bot, pid: self()}],
                 context.arena
               )
    end

    test "when bot_self_play is false, but user self play is true, different bots from the same user can play themselves",
         context do
      context =
        update_in(context.arena, &Map.merge(&1, %{bot_self_play: false, user_self_play: true}))

      assert [%{game: _}] =
               make_matches(
                 [%{bot: context.bot, pid: self()}, %{bot: context.other_bot, pid: self()}],
                 context.arena
               )
    end

    test "when user_self_play is false it won't match two of the same users together", context do
      context = update_in(context.arena, &Map.put(&1, :user_self_play, false))

      assert [] ==
               make_matches(
                 [%{bot: context.bot, pid: self()}, %{bot: context.other_bot, pid: self()}],
                 context.arena
               )
    end
  end
end
