defmodule BattleBoxWeb.BotController do
  use BattleBoxWeb, :controller
  alias BattleBoxWeb.PageView
  alias BattleBox.{Repo, Bot, User}

  def new(conn, _params) do
    changeset = Bot.changeset(%Bot{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(%{assigns: %{current_user: user}} = conn, %{"bot" => params}) do
    user
    |> Ecto.build_assoc(:bots)
    |> Bot.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, bot} ->
        redirect(conn, to: Routes.user_bot_path(conn, :show, user.username, bot.name))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"user_username" => username, "name" => name}) do
    with %User{} = user <- Repo.get_by(User, username: username),
         %Bot{} = bot <- Repo.get_by(Bot, name: name, user_id: user.id) do
      bot = Repo.preload(bot, :user)
      render(conn, "show.html", bot: bot)
    else
      nil ->
        conn
        |> put_status(404)
        |> put_view(PageView)
        |> render("not_found.html", message: "Bot not found")
    end
  end

  def index(conn, %{"user_username" => username}) do
    Repo.get_by(User, username: username)
    |> Repo.preload(:bots)
    |> case do
      %User{} = user ->
        render(conn, "index.html", user: user)

      nil ->
        conn
        |> put_status(404)
        |> put_view(PageView)
        |> render("not_found.html", message: "User (#{username}) not found")
    end
  end
end
