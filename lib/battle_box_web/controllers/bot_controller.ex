defmodule BattleBoxWeb.BotController do
  use BattleBoxWeb, :controller
  alias BattleBoxWeb.PageView
  alias BattleBox.Bot

  def new(conn, _params) do
    changeset = Bot.changeset(%Bot{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(%{assigns: %{user: user}} = conn, %{"bot" => bot}) do
    params = Map.put(bot, "user_id", user.id)

    case Bot.create(params) do
      {:ok, bot} ->
        conn
        |> put_flash(:info, "Bot created successfully.")
        |> redirect(to: Routes.bot_path(conn, :show, bot.id))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    case Bot.get_by_id(id) do
      %Bot{} = bot ->
        render(conn, "show.html", bot: bot)

      nil ->
        conn
        |> put_status(404)
        |> put_view(PageView)
        |> render("not_found.html", message: "Bot not found")
    end
  end
end
