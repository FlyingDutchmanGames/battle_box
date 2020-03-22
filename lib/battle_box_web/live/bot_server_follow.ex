defmodule BattleBoxWeb.BotServerFollow do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.{BotView, PageView}
  alias BattleBox.GameEngine

  def mount(%{"bot_server_id" => bot_server_id}, _session, socket) do
    case GameEngine.get_bot_server(game_engine(), bot_server_id) do
      nil ->
        {:ok, assign(socket, not_found: true)}

      bot_server ->
        if connected?(socket) do
          Process.monitor(bot_server.pid)
        end

        {:ok, assign(socket, bot_server: bot_server)}
    end
  end

  def handle_info(
        {:DOWN, _ref, :process, pid, _reason},
        %{assigns: %{bot_server: %{pid: pid}}} = socket
      ) do
    {:noreply, assign(socket, not_found: true)}
  end

  def render(%{not_found: true}) do
    PageView.render("not_found.html", %{message: "(It's Probably Dead 👻)"})
  end

  def render(assigns) do
    BotView.render("follow.html", assigns)
  end
end
