defmodule BattleBox.GameEngine.AiServerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Bot, GameEngine, GameEngine.AiServer}

  defmodule LogicModule do
  end

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, GameEngine.names(name)}
  end

  setup do
    {:ok, user} = create_user(id: @user_id)

    {:ok, bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "test-bot"})
      |> Repo.insert()

    bot = Repo.preload(bot, :user)

    {:ok, arena} = robot_game_arena(user: user, arena_name: "test-arena")

    %{arena: arena, bot: bot}
  end

  test "you can start the thing", context do
    {:ok, ai_server, %{bot_server_pid: bot_server_pid}} =
      GameEngine.start_ai(context.game_engine, %{
        bot: context.bot,
        arena: context.arena,
        logic_module: LogicModule
      })

    assert Process.alive?(ai_server)
    assert Process.alive?(bot_server_pid)
  end
end
