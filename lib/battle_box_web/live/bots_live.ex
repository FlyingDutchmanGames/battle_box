defmodule BattleBoxWeb.BotsLive do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.{BotView, PageView}
  alias BattleBox.{User, Bot, Repo}

  @refresh_rate_ms 1000

  def mount(%{"user_id" => user_id}, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(@refresh_rate_ms, :refresh)
    end

    case User.get_by_id(user_id) do
      %User{} = user ->
        {:ok, assign(socket, user: user, bots: bots_for_user(user.id))}

      nil ->
        {:ok, assign(socket, not_found: true)}
    end
  end

  def handle_info(:refresh, socket) do
    {:noreply, socket}
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
end
