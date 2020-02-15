defmodule BattleBox.Test.DataHelpers do
  alias BattleBox.{User, Repo}
  import Plug.Test, only: [init_test_session: 2]
  import Plug.Conn

  def signin(conn, opts \\ %{}) do
    user_id = opts[:user_id] || Ecto.UUID.generate()

    {:ok, user} =
      User.changeset(%User{id: user_id}, %{
        github_id: 1,
        name: "NAME"
      })
      |> Repo.insert()

    conn
    |> init_test_session(token: "foo")
    |> put_session(:user_id, user.id)
  end
end
