defmodule BattleBox.GameEngine.PubSub do
  use Supervisor
  alias BattleBox.GameEngine

  def start_link(%{names: names} = opts) do
    Supervisor.start_link(__MODULE__, opts, name: names.pubsub)
  end

  def init(%{names: names}) do
    children = [{Registry, keys: :duplicate, name: registry_name(names.game_engine)}]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def broadcast_bot_server_start(game_engine, %{lobby: _, bot: bot, bot_server_id: id}) do
    Registry.dispatch(registry_name(game_engine), "user:#{bot.user_id}", fn entries ->
      for {pid, events} <- entries,
          :bot_server_start in events,
          do: send(pid, {:bot_server_start, id})
    end)
  end

  def broadcast_bot_server_update(game_engine, %{lobby: _, bot: _, bot_server_id: id}) do
    Registry.dispatch(registry_name(game_engine), "bot_server:#{id}", fn entries ->
      for {pid, events} <- entries,
          :bot_server_update in events,
          do: send(pid, {:bot_server_update, id})
    end)
  end

  def broadcast_game_start(game_engine, %{id: game_id} = game) when not is_nil(game_id) do
    lobby_id = get_lobby_id(game)

    ["lobby:#{lobby_id}"]
    |> Enum.each(fn topic ->
      Registry.dispatch(registry_name(game_engine), topic, fn entries ->
        for {pid, events} <- entries, :game_start in events do
          send(pid, {:game_start, game_id})
        end
      end)
    end)
  end

  def broadcast_game_update(game_engine, %{id: game_id} = game) when not is_nil(game_id) do
    lobby_id = get_lobby_id(game)

    ["game:#{game_id}", "lobby:#{lobby_id}"]
    |> Enum.each(fn topic ->
      Registry.dispatch(registry_name(game_engine), topic, fn entries ->
        for {pid, events} <- entries, :game_update in events do
          send(pid, {:game_update, game_id})
        end
      end)
    end)
  end

  def subscribe_to_lobby_events(game_engine, lobby_id, events) do
    {:ok, _pid} = Registry.register(registry_name(game_engine), "lobby:#{lobby_id}", events)
    :ok
  end

  def subscribe_to_user_events(game_engine, user_id, events) do
    {:ok, _pid} = Registry.register(registry_name(game_engine), "user:#{user_id}", events)
    :ok
  end

  def subscribe_to_game_events(game_engine, game_id, events) do
    {:ok, _pid} = Registry.register(registry_name(game_engine), "game:#{game_id}", events)
    :ok
  end

  def subscribe_to_bot_server_events(game_engine, bot_server_id, events) do
    {:ok, _pid} =
      Registry.register(registry_name(game_engine), "bot_server:#{bot_server_id}", events)

    :ok
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
