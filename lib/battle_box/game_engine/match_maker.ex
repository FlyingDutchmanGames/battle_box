defmodule BattleBox.GameEngine.MatchMaker do
  use Supervisor
  alias BattleBox.{Arena, Bot, Game, GameEngine, GameEngine.MatchMakerServer}
  alias BattleBox.Games.AiOpponent

  def practice_match(game_engine, arena, bot, opponent, pid \\ self()) do
    [bot_player | ai_players] = Enum.shuffle(Arena.players(arena))

    case AiOpponent.opponent_modules(arena.game_type, opponent) do
      {:ok, []} ->
        {:error, :no_opponent_matching}

      {:ok, ai_mods} ->
        combatants =
          create_ai_servers(game_engine, ai_players, ai_mods)
          |> Map.put(bot_player, %{bot: bot, pid: pid})

        game = Game.build(arena, for({player, %{bot: bot}} <- combatants, do: {player, bot}))
        player_pid_mapping = Map.new(for {player, %{pid: pid}} <- combatants, do: {player, pid})

        {:ok, _pid} =
          GameEngine.start_game(game_engine, %{players: player_pid_mapping, game: game})

        {:ok, %{game_id: game.id}}
    end
  end

  def join_queue(game_engine, arena, %Bot{} = bot, pid \\ self()) when is_atom(game_engine) do
    {:ok, _registry} =
      Registry.register(match_maker_registry_name(game_engine), arena, %{
        bot: bot,
        pid: pid
      })

    :ok
  end

  def queue_for_arena(game_engine, arena) do
    Registry.lookup(match_maker_registry_name(game_engine), arena)
    |> Enum.map(fn {enqueuer_pid, match_details} ->
      Map.put(match_details, :enqueuer_pid, enqueuer_pid)
    end)
  end

  def arenas_with_queued_players(game_engine) do
    Registry.select(match_maker_registry_name(game_engine), [{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.uniq()
  end

  def dequeue_self(game_engine) when is_atom(game_engine) do
    registry = match_maker_registry_name(game_engine)

    for key <- Registry.keys(registry, self()) do
      :ok = Registry.unregister(registry, key)
    end

    :ok
  end

  def dequeue_self(game_engine, arena_id) when is_atom(game_engine) do
    :ok = Registry.unregister(match_maker_registry_name(game_engine), arena_id)
  end

  def start_link(%{names: names} = opts) do
    Supervisor.start_link(__MODULE__, opts, name: names.match_maker)
  end

  def init(%{names: names}) do
    children = [
      {MatchMakerServer, %{names: names}},
      {Registry, keys: :duplicate, name: names.match_maker_registry}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp create_ai_servers(game_engine, ai_players, ai_mods) when ai_mods != [] do
    for player <- ai_players, into: %{} do
      opponent_module = Enum.random(ai_mods)
      {:ok, bot} = Bot.system_bot(opponent_module.name)
      {:ok, ai_server} = GameEngine.start_ai(game_engine, %{logic: opponent_module})
      {player, %{bot: bot, pid: ai_server}}
    end
  end

  defp match_maker_registry_name(game_engine) do
    GameEngine.names(game_engine).match_maker_registry
  end
end
