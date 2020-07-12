defmodule BattleBox.GameEngine.PubSub do
  use Supervisor
  alias BattleBox.GameEngine

  @allowed_event_types [:game_update, :game_start, :bot_server_start, :bot_server_update]

  def subscribe_to_arena_events(game_engine, arena_id, events),
    do: subscribe(game_engine, {:arena, arena_id}, events)

  def subscribe_to_user_events(game_engine, user_id, events),
    do: subscribe(game_engine, {:user, user_id}, events)

  def subscribe_to_game_events(game_engine, game_id, events),
    do: subscribe(game_engine, {:game, game_id}, events)

  def subscribe_to_bot_events(game_engine, bot_id, events),
    do: subscribe(game_engine, {:bot, bot_id}, events)

  def subscribe_to_bot_server_events(game_engine, bot_server_id, events),
    do: subscribe(game_engine, {:bot_server, bot_server_id}, events)

  def broadcast_bot_server_start(game_engine, %{bot: bot, bot_server_id: id}) do
    topics = [{:bot_server, id}, {:bot, bot.id}, {:user, bot.user_id}]
    dispatch_event_to_topics(game_engine, topics, :bot_server_start, id)
  end

  def broadcast_bot_server_update(game_engine, %{bot: bot, bot_server_id: id}) do
    topics = [{:bot_server, id}, {:bot, bot.id}, {:user, bot.user_id}]
    dispatch_event_to_topics(game_engine, topics, :bot_server_update, id)
  end

  def broadcast_game_start(game_engine, %{id: game_id} = game) when not is_nil(game_id) do
    topics =
      Enum.flat_map(game.game_bots, fn game_bot ->
        [{:bot, game_bot.bot.id}, {:user, game_bot.bot.user_id}]
      end)

    topics = [{:arena, get_arena_id(game)} | topics]
    dispatch_event_to_topics(game_engine, topics, :game_start, game_id)
  end

  def broadcast_game_update(game_engine, %{id: game_id} = game) when not is_nil(game_id) do
    topics =
      Enum.flat_map(game.game_bots, fn game_bot ->
        [{:bot, game_bot.bot.id}, {:user, game_bot.bot.user_id}]
      end)

    topics = [{:game, "*"}, {:game, game_id}, {:arena, get_arena_id(game)} | topics]
    dispatch_event_to_topics(game_engine, topics, :game_update, game_id)
  end

  def start_link(%{names: names} = opts) do
    Supervisor.start_link(__MODULE__, opts, name: names.pubsub)
  end

  def init(%{names: names}) do
    children = [{Registry, keys: :duplicate, name: registry_name(names.game_engine)}]

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp subscribe(game_engine, topic, events) do
    :ok = validate_event_types!(events)
    {:ok, _pid} = Registry.register(registry_name(game_engine), topic, events)
    :ok
  end

  defp dispatch_event_to_topics(game_engine, topics, event_name, payload) do
    Enum.each(topics, fn topic ->
      Registry.dispatch(registry_name(game_engine), topic, fn entries ->
        for {pid, events} <- entries, event_name in events do
          send(pid, {topic, event_name, payload})
        end
      end)
    end)
  end

  defp get_arena_id(game) do
    case game do
      %{arena: %{id: arena_id}} when not is_nil(arena_id) -> arena_id
      %{arena_id: arena_id} when not is_nil(arena_id) -> arena_id
    end
  end

  defp registry_name(game_engine) do
    GameEngine.names(game_engine).pubsub
    |> Module.concat(Registry)
  end

  defp validate_event_types!(events) do
    result = events -- @allowed_event_types

    unless result == [],
      do:
        raise(
          ArgumentError,
          """
          Only Events Types #{inspect(@allowed_event_types)} are allowed to be subscribed to
          instead received: #{inspect(events)}, which contains illegal events #{inspect(result)}
          """
        )

    :ok
  end
end
