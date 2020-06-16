defmodule BattleBoxWeb.BotController do
  use BattleBoxWeb, :controller
  alias BattleBoxWeb.PageView
  alias BattleBox.{Repo, Bot, User}
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

  def update(
        %{assigns: %{current_user: %{id: user_id} = user}} = conn,
        %{"name" => name, "bot" => params}
      ) do
    Bot
    |> where(name: ^name, user_id: ^user_id)
    |> preload(:user)
    |> Repo.one()
    |> case do
      nil ->
        render404(conn, "Bot (#{name}) Not Found for User (#{user.username})")

      %Bot{} = bot ->
        bot
        |> Bot.changeset(params)
        |> Repo.update()
        |> case do
          {:ok, bot} ->
            redirect(conn, to: Routes.user_bot_path(conn, :show, user.username, bot.name))

          {:error, changeset} ->
            render(conn, "edit.html", changeset: changeset, bot: bot)
        end
    end
  end

  def show(conn, %{"user_username" => username, "name" => name}) do
    with {:user, %User{} = user} <- {:user, Repo.get_by(User, username: username)},
         {:bot, %Bot{} = bot} <- {:bot, Repo.get_by(Bot, name: name, user_id: user.id)},
         bot <- Repo.preload(bot, :user) do
      nav_segments = [{bot.user, :bots}, bot.name]

      nav_options = [
        {:games, bot},
        {:follow, bot},
        if(conn.assigns[:current_user] && conn.assigns.current_user.id == bot.user_id,
          do: {:edit, bot},
          else: {:inaccessible, "Edit"}
        )
      ]

      render(conn, "show.html", bot: bot, nav_segments: nav_segments, nav_options: nav_options)
    else
      {:user, nil} -> render404(conn, "User (#{username}) not found")
      {:bot, nil} -> render404(conn, "Bot (#{name}) not found")
    end
  end

  def edit(%{assigns: %{current_user: %{id: user_id} = user}} = conn, %{"name" => name}) do
    Bot
    |> where(name: ^name, user_id: ^user_id)
    |> preload(:user)
    |> Repo.one()
    |> case do
      %Bot{} = bot ->
        changeset = Bot.changeset(bot)
        render(conn, "edit.html", changeset: changeset, bot: bot)

      nil ->
        render404(conn, "Bot (#{name}) Not Found for User (#{user.username})")
    end
  end

  def index(conn, %{"user_username" => username} = params) do
    Repo.get_by(User, username: username)
    |> case do
      %User{} = user ->
        bots =
          Bot
          |> where(user_id: ^user.id)
          |> order_by(desc: :inserted_at)
          |> paginate(params)
          |> Repo.all()

        nav_segments = [user, "Bots"]

        nav_options = [
          if(conn.assigns[:current_user] && conn.assigns.current_user.id == user.id,
            do: {:new, :bot},
            else: {:inaccessible, "New"}
          )
        ]

        pagination_info = pagination_info(params)
        to_page = to_page(conn, params, pagination_info)

        render(conn, "index.html",
          user: user,
          bots: bots,
          nav_segments: nav_segments,
          nav_options: nav_options,
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
