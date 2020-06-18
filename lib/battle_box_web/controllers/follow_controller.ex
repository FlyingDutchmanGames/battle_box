defmodule BattleBoxWeb.FollowController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Repo, Arena, User, Bot}

  def follow(conn, %{"user_username" => username} = params) do
    case Repo.get_by(User, username: username) do
      nil ->
        render404(conn, {User, username})

      user ->
        case params do
          %{"arena_name" => name} ->
            case Repo.get_by(Arena, name: name, user_id: user.id) do
              nil ->
                render404(conn, {Arena, name, username})

              arena ->
                arena = Repo.preload(arena, :user)

                render(conn, "follow.html", %{
                  nav_segments: [arena, "Follow"],
                  follow: {Arena, arena.id},
                  follow_back: %{"user" => username, "arena" => name}
                })
            end

          %{"bot_name" => name} ->
            case Repo.get_by(Bot, name: name, user_id: user.id) do
              nil ->
                render404(conn, {Bot, name, username})

              bot ->
                bot = Repo.preload(bot, :user)

                render(conn, "follow.html", %{
                  nav_segments: [bot, "Follow"],
                  follow: {Bot, bot.id},
                  follow_back: %{"user" => username, "bot" => name}
                })
            end

          _ ->
            render(conn, "follow.html", %{
              nav_segments: [user, "Follow"],
              follow: {User, user.id},
              follow_back: %{"user" => username}
            })
        end
    end
  end
end
