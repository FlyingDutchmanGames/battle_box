defmodule BattleBox.GameEngine.PubSub do
  use Supervisor
  alias BattleBox.GameEngine

  def subscribe_to_lobby_events(game_engine, lobby_id, events),
    do: subscribe(game_engine, "lobby:#{lobby_id}", events)

  def subscribe_to_user_events(game_engine, user_id, events),
    do: subscribe(game_engine, "user:#{user_id}", events)

  def subscribe_to_game_events(game_engine, game_id, events),
    do: subscribe(game_engine, "game:#{game_id}", events)

  def subscribe_to_bot_events(game_engine, bot_id, events) do
    subscribe(game_engine, "bot:#{bot_id}", events)
  end

  def subscribe_to_bot_server_events(game_engine, bot_server_id, events),
    do: subscribe(game_engine, "bot_server:#{bot_server_id}", events)

  def broadcast_bot_server_start(game_engine, %{lobby: lobby, bot: bot, bot_server_id: id}) do
    topics = ["bot_server:#{id}", "bot:#{bot.id}", "user:#{bot.user_id}", "lobby:#{lobby.id}"]
    dispatch_event_to_topics(game_engine, topics, :bot_server_start, id)
  end

  def broadcast_bot_server_update(game_engine, %{lobby: lobby, bot: bot, bot_server_id: id}) do
    topics = ["bot_server:#{id}", "bot:#{bot.id}", "user:#{bot.user_id}", "lobby:#{lobby.id}"]
    dispatch_event_to_topics(game_engine, topics, :bot_server_update, id)
  end

  def broadcast_game_start(game_engine, %{id: game_id} = game) when not is_nil(game_id) do
    lobby_id = get_lobby_id(game)
    topics = ["lobby:#{lobby_id}"]
    dispatch_event_to_topics(game_engine, topics, :game_start, game_id)
  end

  def broadcast_game_update(game_engine, %{id: game_id} = game) when not is_nil(game_id) do
    lobby_id = get_lobby_id(game)
    topics = ["game:#{game_id}", "lobby:#{lobby_id}"]
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
    {:ok, _pid} = Registry.register(registry_name(game_engine), topic, events)
    :ok
  end

  defp dispatch_event_to_topics(game_engine, topics, event_name, payload) do
    Enum.each(topics, fn topic ->
      Registry.dispatch(registry_name(game_engine), topic, fn entries ->
        for {pid, events} <- entries, event_name in events do
          send(pid, {event_name, payload})
        end
      end)
    end)
  end

  defp get_lobby_id(game) do
    case game do
      %{lobby: %{id: lobby_id}} when not is_nil(lobby_id) -> lobby_id
      %{lobby_id: lobby_id} when not is_nil(lobby_id) -> lobby_id
    end
  end

  defp registry_name(game_engine) do
    GameEngine.names(game_engine).pubsub
    |> Module.concat(Registry)
  end
end
