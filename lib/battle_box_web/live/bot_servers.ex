defmodule BattleBoxWeb.Live.BotServers do
  use BattleBoxWeb, :live_view
  alias BattleBox.{Repo, GameEngine}
  alias BattleBoxWeb.BotView

  def mount(_params, %{"bot" => bot}, socket) do
    bot_servers = GameEngine.get_bot_servers_with_bot_id(game_engine(), bot.id)

    if connected?(socket) do
      for %{pid: pid} <- bot_servers, do: Process.monitor(pid)
      GameEngine.subscribe_to_bot_events(game_engine(), bot.id, [:bot_server_start])
    end

    {:ok, assign(socket, bot_servers: bot_servers)}
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

  def render(assigns) do
    BotView.render("_bot_servers.html", assigns)
  end
end
