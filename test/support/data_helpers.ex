defmodule BattleBox.Test.DataHelpers do
  alias BattleBox.{User, Bot, Lobby, Repo}
  import Ecto.Changeset
  import Phoenix.ConnTest

  def signin(conn, opts \\ %{}) do
    opts = Enum.into(opts, %{})

    user =
      case opts do
        %{user: user} ->
          user

        %{} ->
          {:ok, user} = create_user(opts)
          user
      end

    conn
    |> init_test_session(token: "foo")
    |> Plug.Conn.put_session(:user_id, user.id)
  end

  def create_user(opts \\ %{}) do
    user_id = opts[:user_id] || opts[:id] || Ecto.UUID.generate()

    change(%User{id: user_id},
      github_id: :erlang.unique_integer([:positive]),
      avatar_url: "http://not-real.com",
      username: opts[:username] || "username-#{user_id}",
      is_banned: opts[:is_banned] || false,
      is_admin: opts[:is_admin] || false,
      connection_limit: opts[:connection_limit] || 10
    )
    |> Repo.insert()
  end

  def create_bot(opts) do
    opts[:user]
    |> Ecto.build_assoc(:bots)
    |> Bot.changeset(%{name: opts[:bot_name]})
    |> Repo.insert()
  end

  def robot_game_lobby(opts \\ %{}) do
    (opts[:user] || create_user())
    |> Ecto.build_assoc(:lobbies)
    |> Map.put(:command_time_minimum_ms, opts[:command_time_minimum_ms] || 20)
    |> Lobby.changeset(%{
      "name" => opts[:lobby_name] || "lobby-name",
      "game_type" => "robot_game",
      "robot_game_settings" => %{}
    })
    |> Repo.insert()
  end
end
