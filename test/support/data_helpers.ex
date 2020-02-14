defmodule BattleBox.Test.DataHelpers do
  alias BattleBox.{User, Repo}
  import Plug.Test, only: [init_test_session: 2]
  import Plug.Conn

  def signin(conn, opts \\ %{}) do
    {:ok, user} =
      User.changeset(%User{}, %{
        github_id: 1,
        name: "NAME",
        opts: opts[:user_id] || Ecto.UUID.generate()
      })
      |> Repo.insert()

    conn
    |> init_test_session(token: "foo")
    |> put_session(:user_id, user.id)
  end
end
