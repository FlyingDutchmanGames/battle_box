defmodule BattleBox.Test.DataHelpers do
  alias BattleBox.{User, Repo}
  import Plug.Test, only: [init_test_session: 2]
  import Plug.Conn

  def signin(conn, opts \\ %{}) do
    {:ok, user} = create_user(opts)

    conn
    |> init_test_session(token: "foo")
    |> put_session(:user_id, user.id)
  end

  def create_user(opts) do
    user_id = opts[:user_id] || Ecto.UUID.generate()

    User.changeset(%User{id: user_id}, %{
      github_id: 1,
      name: "NAME",
      github_login_name: opts[:github_login_name] || "github_login_name:#{user_id}",
      is_banned: opts[:is_banned] || false,
      is_superadmin: opts[:is_superadmin] || false
    })
    |> Repo.insert()
  end
end
