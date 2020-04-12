defmodule BattleBoxWeb.Admin.Users do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.AdminView
  alias BattleBox.{Repo, User}
  import Ecto.Query, only: [from: 2]

  def mount(params, session, socket) do
    users = Repo.all(from user in User, select: user)
    {:ok, assign(socket, users: users)}
  end

  def handle_event("adjust_ban", %{"_target" => [action, user_id]}, socket)
      when action in ["ban", "unban"] do
    action = Map.fetch!(%{"ban" => true, "unban" => false}, action)
    user = Enum.find(socket.assigns.users, fn user -> user.id == user_id end)
    {:ok, updated_user} = User.set_ban_status(user, action)

    users =
      Enum.map(socket.assigns.users, fn user ->
        if user.id == user_id, do: updated_user, else: user
      end)

    {:noreply, assign(socket, users: users)}
  end

  def render(assigns) do
    AdminView.render("users.html", assigns)
  end
end
