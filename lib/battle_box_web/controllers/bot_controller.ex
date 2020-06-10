defmodule BattleBoxWeb.BotController do
  use BattleBoxWeb, :controller
  alias BattleBoxWeb.PageView
  alias BattleBox.{Repo, Bot, User}
  import BattleBox.Utilities.Paginator, only: [paginate: 2, pagination_info: 1]
  import Ecto.Query

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
    with {:user, %User{} = user} <- {:user, Repo.get_by(User, username: username)},
         {:bot, %Bot{} = bot} <- {:bot, Repo.get_by(Bot, name: name, user_id: user.id)} do
      bot = Repo.preload(bot, :user)
      render(conn, "show.html", bot: bot)
    else
      {:user, nil} -> render404(conn, "User (#{username}) not found")
      {:bot, nil} -> render404(conn, "Bot (#{name}) not found")
    end
  end

  def index(conn, %{"user_username" => username} = params) do
    Repo.get_by(User, username: username)
    |> case do
      %User{} = user ->
        bots =
          Bot
          |> order_by(desc: :inserted_at)
          |> paginate(params)
          |> Repo.all()

        pagination_info = pagination_info(params)
        to_page = to_page(conn, params, pagination_info)

        render(conn, "index.html",
          user: user,
          bots: bots,
          pagination_info: pagination_info,
          to_page: to_page
        )

      nil ->
        render404(conn, "User (#{username}) not found")
    end
  end

  defp render404(conn, message) do
    conn
    |> put_status(404)
    |> put_view(PageView)
    |> render("not_found.html", message: message)
  end

  defp to_page(conn, %{"user_username" => username}, %{per_page: per_page}) do
    fn page -> Routes.user_bot_path(conn, :index, username, %{page: page, per_page: per_page}) end
  end
end
