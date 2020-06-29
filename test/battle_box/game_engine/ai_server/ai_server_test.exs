defmodule BattleBox.GameEngine.AiServerTest do
  use BattleBox.DataCase, async: false
  alias BattleBox.{Bot, GameEngine}

  @user_id Ecto.UUID.generate()

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
    {:ok, ai_server, %{bot_server: %{pid: bot_server_pid, id: bot_server_id}}} =
      GameEngine.start_ai(context.game_engine, %{
        bot: context.bot,
        arena: context.arena,
        logic_module: LogicModule
      })

    assert Process.alive?(ai_server)
    assert Process.alive?(bot_server_pid)
    assert %{pid: ^bot_server_pid} = GameEngine.get_bot_server(context.game_engine, bot_server_id)
  end
end
