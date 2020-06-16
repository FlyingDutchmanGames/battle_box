defmodule BattleBoxWeb.Live.FollowBack do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.FollowView

  def mount(_params, %{"game_pid" => game_pid, "follow" => follow}, socket) do
    socket = assign(socket, follow: follow, follow_back_path: follow_back_path(socket, follow))

    case game_pid do
      nil ->
        {:ok, assign(socket, mode: :passive, game_alive?: false)}

      pid when is_pid(pid) ->
        if connected?(socket), do: Process.monitor(pid)
        {:ok, assign(socket, mode: :active, game_alive?: true)}
    end
  end

  def handle_event("mode-" <> mode, _event, socket) when mode in ["active", "passive"] do
    {:noreply, assign(socket, mode: String.to_existing_atom(mode))}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    case socket.assigns.mode do
      :active ->
        {:noreply, redirect(socket, to: socket.assigns.follow_back_path)}

      :passive ->
        {:noreply, assign(socket, game_alive?: false)}
    end
  end

  def render(assigns) do
    FollowView.render("_follow_back.html", assigns)
  end

  defp follow_back_path(socket, follow) do
    case follow do
      %{"arena" => arena_name, "user" => username} ->
        Routes.user_arena_follow_path(socket, :follow, username, arena_name)

      %{"bot" => bot_name, "user" => username} ->
        Routes.user_bot_follow_path(socket, :follow, username, bot_name)

      %{"user" => username} ->
        Routes.user_follow_path(socket, :follow, username)
    end
  end
end
