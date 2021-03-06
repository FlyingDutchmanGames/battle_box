defmodule BattleBoxWeb.GithubLoginController do
  use BattleBoxWeb, :controller
  alias BattleBox.{User, Utilities.Github}

  def github_login(conn, _params) do
    state = make_state()

    conn
    |> put_session(:github_auth_state, state)
    |> redirect(external: authorization_url(conn, state))
  end

  def github_callback(conn, %{"code" => code, "state" => state}) do
    true = state == get_session(conn, :github_auth_state)
    {:ok, access_token} = Github.token_exchange(code, state)
    {:ok, user} = Github.get_user(access_token)
    Map.put(user, "access_token", access_token)
    {:ok, user} = User.upsert_from_github(user)

    conn
    |> delete_session(:github_auth_state)
    |> put_session(:user_id, user.id)
    |> redirect(to: "/")
  end

  defp authorization_url(conn, state) do
    params =
      URI.encode_query(%{
        "state" => state,
        "redirect_uri" => Routes.github_login_url(conn, :github_callback),
        "client_id" => Keyword.fetch!(config(), :client_id)
      })

    "https://github.com/login/oauth/authorize?#{params}"
  end

  defp config do
    Application.fetch_env!(:battle_box, :github)
  end

  defp make_state do
    :crypto.strong_rand_bytes(32)
    |> Base.encode16(case: :lower)
  end
end
