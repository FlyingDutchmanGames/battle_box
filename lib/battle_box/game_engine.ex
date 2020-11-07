defmodule BattleBox.GameEngine do
  use Supervisor
  alias BattleBox.GameEngine.GameServer.GameSupervisor, as: GameSup
  alias BattleBox.GameEngine.BotServer.BotSupervisor, as: BotSup
  alias BattleBox.GameEngine.AiServer.AiSupervisor, as: AiSup
  alias BattleBox.GameEngine.HumanServer.HumanSupervisor, as: HumanSup
  alias BattleBox.GameEngine.MatchMaker, as: MatchMakerSup
  alias BattleBox.GameEngine.PubSub, as: GameEnginePubSub
  alias BattleBox.GameEngine.MatchMakerServer

  @default_name GameEngine
  def default_name, do: @default_name

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, @default_name)
    Supervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    supervisor_opts = %{names: names(name)}

    children = [
      {Registry, keys: :unique, name: game_registry_name(name)},
      {Registry, keys: :unique, name: bot_registry_name(name)},
      {Registry, keys: :unique, name: ai_registry_name(name)},
      {Registry, keys: :unique, name: connection_registry_name(name)},
      {Registry, keys: :unique, name: human_registry_name(name)},
      {GameEnginePubSub, supervisor_opts},
      {AiSup, supervisor_opts},
      {HumanSup, supervisor_opts},
      {GameSup, supervisor_opts},
      {BotSup, supervisor_opts},
      {MatchMakerSup, supervisor_opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defdelegate arenas_with_queued_players(game_engine), to: MatchMakerSup
  defdelegate dequeue_self(game_engine), to: MatchMakerSup
  defdelegate dequeue_self(game_engine, arena_id), to: MatchMakerSup
  defdelegate join_queue(game_engine, arena, bot, pid \\ self()), to: MatchMakerSup
  defdelegate practice_match(game_engine, arena, bot, opponent, pid \\ self()), to: MatchMakerSup
  defdelegate queue_for_arena(game_engine, arena), to: MatchMakerSup

  defdelegate subscribe_to_bot_events(game_engine, bot_id, events), to: GameEnginePubSub
  defdelegate subscribe_to_user_events(game_engine, user_id, events), to: GameEnginePubSub
  defdelegate subscribe_to_arena_events(game_engine, arena_id, events), to: GameEnginePubSub
  defdelegate subscribe_to_game_events(game_engine, game_id, events), to: GameEnginePubSub

  defdelegate broadcast_bot_server_start(game_engine, bot_server), to: GameEnginePubSub
  defdelegate broadcast_bot_server_update(game_engine, bot_server), to: GameEnginePubSub
  defdelegate broadcast_game_start(game_engine, game), to: GameEnginePubSub
  defdelegate broadcast_game_update(game_engine, game), to: GameEnginePubSub

  defdelegate subscribe_to_bot_server_events(game_engine, bot_server_id, events),
    to: GameEnginePubSub

  defdelegate start_ai(game_engine, opts), to: AiSup

  defdelegate start_human(game_engine, opts), to: HumanSup

  defdelegate start_bot(game_engine, opts), to: BotSup
  defdelegate get_bot_servers_with_user_id(game_engine, user_id), to: BotSup
  defdelegate get_bot_servers_with_bot_id(game_engine, bot_id), to: BotSup

  defdelegate start_game(game_engine, opts), to: GameSup
  defdelegate get_live_games(game_engine), to: GameSup
  defdelegate get_live_games_with_arena_id(game_engine, arena_id), to: GameSup

  defdelegate force_match_make(game_engine), to: MatchMakerServer

  def get_human_server(game_engine, human_server_id),
    do: get_process(human_registry_name(game_engine), human_server_id, :human_server_id)

  def get_game_server(game_engine, game_id),
    do: get_process(game_registry_name(game_engine), game_id, :game_id)

  def get_bot_server(game_engine, bot_server_id),
    do: get_process(bot_registry_name(game_engine), bot_server_id, :bot_server_id)

  def get_connection(game_engine, connection_id),
    do: get_process(connection_registry_name(game_engine), connection_id, :connection_id)

  def names(name \\ @default_name) do
    %{
      ai_registry: ai_registry_name(name),
      ai_supervisor: ai_supervisor_name(name),
      bot_registry: bot_registry_name(name),
      bot_supervisor: bot_supervisor_name(name),
      connection_registry: connection_registry_name(name),
      game_engine: name,
      game_registry: game_registry_name(name),
      game_supervisor: game_supervisor_name(name),
      human_registry: human_registry_name(name),
      human_supervisor: human_supervisor_name(name),
      match_maker: match_maker_name(name),
      match_maker_registry: match_maker_registry_name(name),
      match_maker_server: match_maker_server_name(name),
      pubsub: pubsub_name(name)
    }
  end

  defp ai_registry_name(name), do: Module.concat(name, Ai.Registry)
  defp ai_supervisor_name(name), do: Module.concat(name, AiSupervisor)
  defp bot_registry_name(name), do: Module.concat(name, BotRegistry)
  defp bot_supervisor_name(name), do: Module.concat(name, BotSupervisor)
  defp connection_registry_name(name), do: Module.concat(name, Connection.Registry)
  defp game_registry_name(name), do: Module.concat(name, GameRegistry)
  defp game_supervisor_name(name), do: Module.concat(name, GameSupervisor)
  defp human_registry_name(name), do: Module.concat(name, Human.Registry)
  defp human_supervisor_name(name), do: Module.concat(name, Elixir.HumanSupervisor)
  defp match_maker_name(name), do: Module.concat(name, MatchMaker)
  defp match_maker_registry_name(name), do: Module.concat(name, MatchMaker.Registry)
  defp match_maker_server_name(name), do: Module.concat(name, MatchMaker.MatchMakerServer)
  defp pubsub_name(name), do: Module.concat(name, PubSub)

  defp get_process(registry, id, id_name) do
    case Registry.lookup(registry, id) do
      [{pid, attributes}] -> Map.merge(attributes, %{:pid => pid, id_name => id})
      [] -> nil
    end
  end
end
