defmodule BattleBoxWeb.Admin.UserController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Repo, User}
  import Ecto.Query

  def show(conn, %{"username" => username}) do
    case Repo.get_by(User, username: username) do
      %User{} = user ->
        nav_segments = [:admin, {:admin, user}]
        nav_options = [{:admin, {:edit, user}}]

        render(conn, "show.html", user: user, nav_segments: nav_segments, nav_options: nav_options)

      nil ->
        render404(conn, {User, username})
    end
  end

  def edit(conn, %{"username" => username}) do
    case Repo.get_by(User, username: username) do
      %User{} = user ->
        changeset = User.admin_changeset(user)
        render(conn, "edit.html", user: user, changeset: changeset)

      nil ->
        render404(conn, {User, username})
    end
  end

  def update(conn, %{"username" => username, "user" => user_params}) do
    case Repo.get_by(User, username: username) do
      %User{} = user ->
        user
        |> User.admin_changeset(user_params)
        |> Repo.update()
        |> case do
          {:ok, user} ->
            redirect(conn, to: Routes.admin_user_path(conn, :show, user.username))

          {:error, changeset} ->
            render(conn, "edit.html", user: user, changeset: changeset)
        end

      nil ->
        render404(conn, {User, username})
    end
  end

  def index(conn, params) do
    users =
      User
      |> order_by(desc: :inserted_at)
      |> paginate(params)
      |> Repo.all()

    pagination_info = pagination_info(params)

    render(conn, "index.html",
      users: users,
      to_page: &to_page(&1, conn, pagination_info),
      pagination_info: pagination_info,
      incomplete_page?: length(users) < pagination_info.per_page
    )
  end

  def to_page(page, conn, %{per_page: per_page}) do
    Routes.admin_user_path(conn, :index, %{page: page, per_page: per_page})
  end
end
