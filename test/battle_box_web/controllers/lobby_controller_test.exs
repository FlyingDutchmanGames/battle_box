defmodule BattleBoxWeb.LobbyControllerTest do
  use BattleBoxWeb.ConnCase, async: false
  import BattleBox.InstalledGames
  alias BattleBox.Lobby

  @user_id Ecto.UUID.generate()

  setup do
    {:ok, user} = create_user(id: @user_id)
    %{user: user}
  end

  describe "show" do
    test "you can view a lobby", %{conn: conn, user: user} do
      {:ok, lobby} = robot_game_lobby(user: user, lobby_name: "test-name")

      conn =
        conn
        |> get("/users/#{user.username}/lobbies/#{lobby.name}")

      assert html_response(conn, 200) =~ "test-name"
    end

    test "A non existant lobby triggers a 404", %{conn: conn, user: user} do
      conn = conn |> get("/users/#{user.username}/lobbies/fake-lobby")

      assert html_response(conn, 404) =~ "Lobby (fake-lobby) not found"
    end
  end

  describe "create" do
    test "creating requires login", %{conn: conn} do
      conn = post(conn, "/lobbies", %{foo: :bar})
      assert redirected_to(conn, 302) =~ "/login"
    end

    test "you can create a lobby", %{conn: conn, user: user} do
      conn =
        conn
        |> signin(user: user)
        |> post("/lobbies", %{
          "lobby" => %{"name" => "FOO", "game_type" => "robot_game", "robot_game_settings" => %{}}
        })

      url = redirected_to(conn, 302)
      %{"user" => username} = Regex.named_captures(~r/\/users\/(?<user>.*)\/lobbies/, url)
      assert URI.encode_www_form(user.username) == username
    end

    test "creating a lobby with the same name as an existing lobby is an error", %{
      conn: conn,
      user: user
    } do
      {:ok, _lobby} = robot_game_lobby(user: user, lobby_name: "FOO")

      conn =
        conn
        |> signin(user: user)
        |> post("/lobbies", %{
          "lobby" => %{"name" => "FOO", "game_type" => "robot_game", "robot_game_settings" => %{}}
        })

      assert html_response(conn, 200) =~ "has already been taken"
    end
  end

  describe "new" do
    test "It asks you the game type if you don't provide a game type", %{conn: conn, user: user} do
      conn =
        conn
        |> signin(user: user)
        |> get("/lobbies/new")

      html = html_response(conn, 200)
      {:ok, document} = Floki.parse_document(html)

      game_types =
        Floki.find(document, "a")
        |> Enum.map(&Floki.attribute(&1, "a", "href"))
        |> List.flatten()
        |> Enum.filter(&String.starts_with?(&1, "/lobbies/new"))
        |> Enum.map(fn "/lobbies/new?game_type=" <> game_type -> game_type end)

      assert Enum.sort(game_types) == Enum.sort(installed_games() |> Enum.map(&"#{&1.name}"))
    end

    test "theres a form to create a new lobby", %{conn: conn, user: user} do
      conn =
        conn
        |> signin(user: user)
        |> get("/lobbies/new?game_type=robot_game")

      html = html_response(conn, 200)
      {:ok, document} = Floki.parse_document(html)
      assert [_form] = Floki.find(document, "form:not(#logout)")
    end
  end

  describe "index" do
    test "it will 404 if the user isn't found", %{conn: conn} do
      conn = get(conn, "/users/FAKE_username/lobbies")
      assert html_response(conn, 404) =~ "User (FAKE_username) not found"
    end

    test "it will show a user's lobbies", %{conn: conn, user: user} do
      for i <- [1, 2, 3] do
        {:ok, _} = robot_game_lobby(user: user, lobby_name: "test-name-#{i}")
      end

      conn = get(conn, "/users/#{user.username}/lobbies")
      html = html_response(conn, 200)
      {:ok, document} = Floki.parse_document(html)

      assert ["Name: test-name-1", "Name: test-name-2", "Name: test-name-3"] =
               Enum.sort(Floki.find(document, ".lobby .name") |> Enum.map(&Floki.text/1))
    end
  end

  describe "edit" do
    test "editing requires login", %{conn: conn} do
      conn = get(conn, "/users/some-username/lobbies/fake-lobby/edit")
      assert redirected_to(conn, 302) =~ "/login"
    end

    test "trying to edit a lobby that doesn't exist is an error", %{conn: conn, user: user} do
      conn =
        conn
        |> signin(user: user)
        |> get("/users/#{user.username}/lobbies/fake-lobby/edit")

      html = html_response(conn, 404)
      assert html =~ "Lobby (fake-lobby) Not Found for User (#{user.username})"
    end

    test "trying to edit someone else's lobby is an error", %{conn: conn, user: user} do
      {:ok, lobby} =
        Lobby.changeset(%Lobby{user_id: Ecto.UUID.generate(), name: "foo"}, %{
          "robot_game_settings" => %{}
        })
        |> Repo.insert()

      conn =
        conn
        |> signin(user: user)
        |> get("/users/#{user.username}/lobbies/#{lobby.name}/edit")

      html = html_response(conn, 404)
      assert html =~ "Lobby (#{lobby.name}) Not Found for User (#{user.username})"
    end

    test "You can edit your own lobby if it exists", %{user: user, conn: conn} do
      {:ok, lobby} =
        user
        |> Ecto.build_assoc(:lobbies)
        |> Lobby.changeset(%{"name" => "foo", "robot_game_settings" => %{}})
        |> Repo.insert()

      conn =
        conn
        |> signin(user: user)
        |> get("/users/#{user.username}/lobbies/#{lobby.name}/edit")

      html = html_response(conn, 200)
      assert html =~ "Edit"
    end
  end

  describe "update" do
    test "updating requires login", %{conn: conn} do
      conn = put(conn, "/users/some-username/lobbies/fake-lobby", %{foo: "bar"})
      assert redirected_to(conn, 302) =~ "/login"
    end

    test "you can't update a lobby that doesn't exist", %{conn: conn, user: user} do
      conn =
        conn
        |> signin(user: user)
        |> put("/users/#{user.username}/lobbies/fake-lobby", %{"lobby" => %{foo: "bar"}})

      html = html_response(conn, 404)
      assert html =~ "Lobby (fake-lobby) Not Found for User (#{user.username})"
    end

    test "trying to update someone else's lobby is an error", %{conn: conn, user: user} do
      {:ok, lobby} =
        Lobby.changeset(%Lobby{user_id: Ecto.UUID.generate(), name: "foo"}, %{
          "robot_game_settings" => %{}
        })
        |> Repo.insert()

      conn =
        conn
        |> signin(user: user)
        |> put("/users/#{user.username}/lobbies/#{lobby.name}", %{"lobby" => %{"name" => "bar"}})

      html = html_response(conn, 404)
      assert html =~ "Lobby (#{lobby.name}) Not Found for User (#{user.username})"
    end

    test "You can update your own lobby if it exists", %{user: user, conn: conn} do
      {:ok, %{id: lobby_id} = lobby} =
        user
        |> Ecto.build_assoc(:lobbies)
        |> Lobby.changeset(%{"name" => "foo", "robot_game_settings" => %{}})
        |> Repo.insert()

      conn =
        conn
        |> signin(user: user)
        |> put("/users/#{user.username}/lobbies/#{lobby.name}", %{"lobby" => %{"name" => "bar"}})

      assert redirected_to(conn, 302) == "/users/#{user.username}/lobbies/bar"
      assert %{name: "bar"} = Repo.get(Lobby, lobby_id)
    end
  end
end
