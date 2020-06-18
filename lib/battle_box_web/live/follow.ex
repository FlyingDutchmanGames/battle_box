defmodule BattleBoxWeb.Live.Follow do
  use BattleBoxWeb, :live_view
  alias BattleBox.{GameEngine, Bot, Arena, User}

  def mount(_params, %{"follow" => :next_available} = session, socket) do
    if connected?(socket) do
      :ok = GameEngine.subscribe_to_game_events(game_engine(), "*", [:game_update])
    end

    {:ok, assign(socket, follow_back: session["follow_back"])}
  end

  def mount(_params, %{"follow" => {type, id}} = session, socket)
      when is_binary(id) and type in [Bot, User, Arena] do
    if connected?(socket) do
      func =
        case type do
          Bot -> :subscribe_to_bot_events
          User -> :subscribe_to_user_events
          Arena -> :subscribe_to_arena_events
        end

      :ok = apply(GameEngine, func, [game_engine(), id, [:game_update]])
    end

    {:ok, assign(socket, follow_back: session["follow_back"])}
  end

  def handle_info({_topic, :game_update, game_id}, socket) do
    {:noreply,
     redirect(socket,
       to: Routes.game_path(socket, :show, game_id, %{follow: socket.assigns.follow_back})
     )}
  end

  def render(assigns) do
    ~L"""
    <div style="display: flex; justify-content: center; padding: 10px;">
      <h1 class="blinking">Waiting for Game to Start</h1>
    </div>
    """
  end
end
