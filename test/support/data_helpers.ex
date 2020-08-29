defmodule BattleBox.Test.DataHelpers do
  alias BattleBox.{ApiKey, User, Bot, Arena, Repo}
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

  def create_key(opts \\ %{}) do
    opts = Enum.into(opts, %{})

    user =
      case opts do
        %{user: user} ->
          user

        _ ->
          {:ok, user} = create_user()
          user
      end

    user
    |> Ecto.build_assoc(:api_keys)
    |> ApiKey.changeset(%{name: "test-key"})
    |> Repo.insert()
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
    opts = Enum.into(opts, %{})

    user =
      case opts do
        %{user: user} ->
          user

        _ ->
          {:ok, user} = create_user()
          user
      end

    user
    |> Ecto.build_assoc(:bots)
    |> Bot.changeset(%{name: opts[:bot_name]})
    |> Repo.insert()
  end

  def marooned_arena(opts \\ %{}) do
    user =
      case opts do
        %{user: user} ->
          user

        _ ->
          {:ok, user} = create_user()
          user
      end

    {:ok, _arena} =
      user
      |> Ecto.build_assoc(:arenas)
      |> Map.put(:command_time_minimum_ms, opts[:command_time_minimum_ms] || 20)
      |> Arena.changeset(%{
        "name" => opts[:arena_name] || "arena-name",
        "game_type" => "marooned",
        "marooned_settings" => %{}
      })
      |> Repo.insert()
  end

  def robot_game_arena(opts \\ %{}) do
    opts = Enum.into(opts, %{})

    user =
      case opts do
        %{user: user} ->
          user

        _ ->
          {:ok, user} = create_user()
          user
      end

    {:ok, _arena} =
      user
      |> Ecto.build_assoc(:arenas)
      |> Map.put(:command_time_minimum_ms, opts[:command_time_minimum_ms] || 20)
      |> Arena.changeset(%{
        "name" => opts[:arena_name] || "arena-name",
        "game_type" => "robot_game",
        "robot_game_settings" => %{}
      })
      |> Repo.insert()
  end
end
