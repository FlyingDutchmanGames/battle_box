defmodule BattleBoxWeb.FollowController do
  use BattleBoxWeb, :controller
  alias BattleBoxWeb.PageView
  alias BattleBox.{Repo, Lobby, User, Bot}

  def follow(conn, %{"user_username" => username} = params) do
    case Repo.get_by(User, username: username) do
      nil ->
        render404(conn, username: username)

      user ->
        assigns =
          Keyword.merge(
            [user: user, lobby: nil, bot: nil],
            hydrate_params(params, user)
          )

        render(conn, "follow.html", hydrate_params(params, user))
    end
  end

  defp render404(conn, username: username) do
    conn
    |> put_status(404)
    |> put_view(PageView)
    |> render("not_found.html", message: "User (#{username}) not found")
  end

  defp hydrate_params(params, user) do
    hydrated =
      params
      |> Enum.map(fn
        {"lobby_name", name} -> {:lobby, Repo.get_by(Lobby, name: name, user_id: user.id)}
        {"bot_name", name} -> {:bot, Repo.get_by(Bot, name: name, user_id: user.id)}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    Keyword.merge([user: user, lobby: nil, bot: nil], hydrated)
  end
end
