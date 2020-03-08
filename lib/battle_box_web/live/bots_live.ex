defmodule BattleBoxWeb.BotsLive do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.{BotView, PageView}
  alias BattleBox.{GameEngine, User, Bot, Repo}

  def mount(%{"user_id" => user_id}, _session, socket) do
    case User.get_by_id(user_id) do
      %User{} = user ->
        bots = bots_for_user(user_id)
        bot_servers = bot_servers_for_user(user_id)

        if connected?(socket) do
          for %{pid: pid} <- bot_servers, do: Process.monitor(pid)
        end

        {:ok, assign(socket, user: user, bots: bots, bot_servers: bot_servers)}

      nil ->
        {:ok, assign(socket, not_found: true)}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, socket) do
    bot_servers = Enum.reject(socket.assigns.bot_servers, & &1.pid == pid)
    {:noreply, assign(socket, :bot_servers, bot_servers)}
  end

  def render(%{not_found: true}) do
    PageView.render("not_found.html", message: "User not found")
  end

  def render(assigns) do
    BotView.render("bots.html", assigns)
  end

  def bots_for_user(user_id) do
    Bot.with_user_id(user_id)
    |> Repo.all()
  end

  def bot_servers_for_user(user_id) do
    GameEngine.get_bot_servers_with_user_id(game_engine(), user_id)
  end
end
