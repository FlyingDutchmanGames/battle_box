defmodule BattleBoxWeb.BotController do
  use BattleBoxWeb, :controller
  alias BattleBoxWeb.PageView
  alias BattleBox.{Repo, Bot}

  def new(conn, _params) do
    changeset = Bot.changeset(%Bot{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(%{assigns: %{current_user: user}} = conn, %{"bot" => params}) do
    result =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(params)
      |> Repo.insert()

    case result do
      {:ok, bot} ->
        redirect(conn, to: Routes.user_bot_path(conn, :show, user.id, bot.name))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"user_id" => user_id, "id" => name}) do
    bot =
      Repo.get_by(Bot, user_id: user_id, name: name)
      |> Repo.preload(:user)

    case bot do
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
