defmodule BattleBoxWeb.Bots do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.{BotView, PageView}
  alias BattleBox.{GameEngine, User, Repo}

  def mount(%{"user_id" => user_identifier}, _session, socket) do
    case User.get_by_identifier(user_identifier) do
      %User{} = user ->
        user = Repo.preload(user, :bots)
        bot_servers = bot_servers_for_user(user.id)

        if connected?(socket) do
          for %{pid: pid} <- bot_servers, do: Process.monitor(pid)
          GameEngine.subscribe_to_user_events(game_engine(), user.id, [:bot_server_start])
        end

        {:ok, assign(socket, user: user, bot_servers: bot_servers)}

      nil ->
        {:ok, assign(socket, not_found: true)}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, socket) do
    bot_servers = Enum.reject(socket.assigns.bot_servers, &(&1.pid == pid))
    {:noreply, assign(socket, :bot_servers, bot_servers)}
  end

  def handle_info({:bot_server_start, bot_server_id}, socket) do
    bot_server = GameEngine.get_bot_server(game_engine(), bot_server_id)
    Process.monitor(bot_server.pid)
    bot_servers = [bot_server | socket.assigns.bot_servers]
    {:noreply, assign(socket, :bot_servers, bot_servers)}
  end

  def render(%{not_found: true}) do
    PageView.render("not_found.html", message: "User not found")
  end

  def render(assigns) do
    BotView.render("bots.html", assigns)
  end

  defp bot_servers_for_user(user_id) do
    GameEngine.get_bot_servers_with_user_id(game_engine(), user_id)
  end
end
