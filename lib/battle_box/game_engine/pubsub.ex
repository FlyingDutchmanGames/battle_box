defmodule BattleBox.GameEngine.PubSub do
  use Supervisor

  def start_link(%{names: names} = opts) do
    Supervisor.start_link(__MODULE__, opts, name: names.pubsub)
  end

  def init(%{names: names}) do
    children = [{Registry, keys: :duplicate, name: registry_name(names.pubsub)}]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def broadcast_bot_server_started(pubsub, %{lobby: _, bot: bot, bot_server_id: id}) do
    Registry.dispatch(registry_name(pubsub), "user:#{bot.user_id}", fn entries ->
      for {pid, events} <- entries,
          :bot_server_start in events,
          do: send(pid, {:bot_server_start, id})
    end)
  end

  def broadcast_game_started(pubsub, %{id: game_id} = game) when not is_nil(game_id) do
    lobby_id = get_lobby_id(game)

    ["lobby:#{lobby_id}"]
    |> Enum.each(fn topic ->
      Registry.dispatch(registry_name(pubsub), topic, fn entries ->
        for {pid, events} <- entries, :game_started in events do
          send(pid, {:game_started, game_id})
        end
      end)
    end)
  end

  def broadcast_game_update(pubsub, %{id: game_id} = game) when not is_nil(game_id) do
    lobby_id = get_lobby_id(game)

    ["game:#{game_id}", "lobby:#{lobby_id}"]
    |> Enum.each(fn topic ->
      Registry.dispatch(registry_name(pubsub), topic, fn entries ->
        for {pid, events} <- entries, :game_update in events do
          send(pid, {:game_update, game_id})
        end
      end)
    end)
  end

  def subscribe_to_lobby_events(pubsub, lobby_id, events) do
    {:ok, _pid} = Registry.register(registry_name(pubsub), "lobby:#{lobby_id}", events)
    :ok
  end

  def subscribe_to_user_events(pubsub, user_id, events) do
    {:ok, _pid} = Registry.register(registry_name(pubsub), "user:#{user_id}", events)
    :ok
  end

  def subscribe_to_game_events(pubsub, game_id, events) do
    {:ok, _pid} = Registry.register(registry_name(pubsub), "game:#{game_id}", events)
    :ok
  end

  defp get_lobby_id(game) do
    case game do
      %{lobby: %{id: lobby_id}} when not is_nil(lobby_id) -> lobby_id
      %{lobby_id: lobby_id} when not is_nil(lobby_id) -> lobby_id
    end
  end

  defp registry_name(pubsub_name) do
    Module.concat(pubsub_name, Registry)
  end
end
