defmodule BattleBox.GameEngine do
  use Supervisor
  alias BattleBox.GameEngine.GameServer.GameSupervisor, as: GameSup
  alias BattleBox.GameEngine.BotServer.BotSupervisor, as: BotSup
  alias BattleBox.GameEngine.MatchMaker, as: MatchMakerSup
  alias BattleBox.GameEngine.PubSub, as: GameEnginePubSub
  alias BattleBox.GameEngine.MatchMakerServer
  alias BattleBox.TcpConnectionServer

  @default_name GameEngine
  def default_name, do: @default_name

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, @default_name)
    Supervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    name = Keyword.fetch!(opts, :name)

    children = [
      {Registry, keys: :unique, name: connection_registry_name(name)},
      {Registry, keys: :unique, name: bot_registry_name(name)},
      {Registry, keys: :unique, name: game_registry_name(name)},
      {GameEnginePubSub, %{names: names(name)}},
      {GameSup, %{names: names(name)}},
      {BotSup, %{names: names(name)}},
      {MatchMakerSup, %{names: names(name)}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def broadcast_bot_server_started(game_engine, bot_server),
    do: GameEnginePubSub.broadcast_bot_server_started(pubsub_name(game_engine), bot_server)

  def broadcast_game_update(game_engine, game),
    do: GameEnginePubSub.broadcast_game_update(pubsub_name(game_engine), game)

  def subscribe_to_user_events(game_engine, user_id, events),
    do: GameEnginePubSub.subscribe_to_user_events(pubsub_name(game_engine), user_id, events)

  def subscribe_to_game_events(game_engine, game_id, events),
    do: GameEnginePubSub.subscribe_to_game_events(pubsub_name(game_engine), game_id, events)

  def start_game(game_engine, opts),
    do: GameSup.start_game(game_supervisor_name(game_engine), opts)

  defdelegate start_bot(game_engine, opts), to: BotSup

  def force_match_make(game_engine),
    do: MatchMakerServer.force_match_make(match_maker_server_name(game_engine))

  def get_game(game_engine, game_id),
    do: get_process(game_registry_name(game_engine), game_id, :game_id)

  def get_live_games(game_engine), do: GameSup.get_live_games(game_registry_name(game_engine))

  def get_connection(game_engine, connection_id),
    do: get_process(connection_registry_name(game_engine), connection_id, :connection_id)

  def get_connections_with_user_id(game_engine, user_id),
    do:
      TcpConnectionServer.get_connections_with_user_id(
        connection_registry_name(game_engine),
        user_id
      )

  def get_bot_server(game_engine, bot_server_id),
    do: get_process(bot_registry_name(game_engine), bot_server_id, :bot_server_id)

  def get_bot_servers_with_user_id(game_engine, user_id),
    do: BotSup.get_bot_servers_with_user_id(bot_registry_name(game_engine), user_id)

  def names(name \\ @default_name) do
    %{
      game_engine: name,
      game_registry: game_registry_name(name),
      game_supervisor: game_supervisor_name(name),
      bot_registry: bot_registry_name(name),
      bot_supervisor: bot_supervisor_name(name),
      match_maker: match_maker_name(name),
      match_maker_server: match_maker_server_name(name),
      match_maker_registry: match_maker_registry_name(name),
      connection_registry: connection_registry_name(name),
      pubsub: pubsub_name(name)
    }
  end

  defp game_registry_name(name), do: Module.concat(name, GameRegistry)
  defp game_supervisor_name(name), do: Module.concat(name, GameSupervisor)
  defp bot_registry_name(name), do: Module.concat(name, BotRegistry)
  defp bot_supervisor_name(name), do: Module.concat(name, BotSupervisor)
  defp match_maker_name(name), do: Module.concat(name, MatchMaker)
  defp match_maker_server_name(name), do: Module.concat(name, MatchMaker.MatchMakerServer)
  defp match_maker_registry_name(name), do: Module.concat(name, MatchMaker.Registry)
  defp connection_registry_name(name), do: Module.concat(name, Connection.Registry)
  defp pubsub_name(name), do: Module.concat(name, PubSub)

  defp get_process(registry, id, id_name) do
    case Registry.lookup(registry, id) do
      [{pid, attributes}] -> Map.merge(attributes, %{:pid => pid, id_name => id})
      [] -> nil
    end
  end
end
