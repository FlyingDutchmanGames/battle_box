defmodule BattleBoxWeb.Live.Follow do
  use BattleBoxWeb, :live_view
  alias BattleBox.{GameEngine, Bot, Arena, User}

  def mount(_params, %{"follow" => {type, id}} = session, socket)
      when is_binary(id) and type in [Bot, User, Arena] do
    if connected?(socket) do
      func =
        case type do
          Bot -> :subscribe_to_bot_events
          User -> :subscribe_to_user_events
          Arena -> :subscribe_to_arena_events
        end

      :ok = apply(GameEngine, func, [game_engine(), id, [:game_started, :game_update]])
    end

    {:ok,
     assign(socket,
       follow_back: session["follow_back"],
       message: session["message"] || "Waiting for Game to Start"
     )}
  end

  def handle_info({_topic, event, game_id}, socket) when event in [:game_update, :game_started] do
    {:noreply,
     redirect(socket,
       to: Routes.game_path(socket, :show, game_id, %{follow: socket.assigns.follow_back})
     )}
  end

  def render(assigns) do
    ~L"""
    <div style="display: flex; justify-content: center; padding: 10px;">
      <h1 class="blinking"><%= @message %></h1>
    </div>
    """
  end
end
