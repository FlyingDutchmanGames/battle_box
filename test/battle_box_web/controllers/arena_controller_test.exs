defmodule BattleBoxWeb.ArenaControllerTest do
  use BattleBoxWeb.ConnCase, async: false
  import BattleBox.InstalledGames
  alias BattleBox.Arena

  @user_id Ecto.UUID.generate()

  setup do
    {:ok, user} = create_user(id: @user_id)
    %{user: user}
  end

  describe "show" do
    test "you can view a arena", %{conn: conn, user: user} do
      {:ok, arena} = robot_game_arena(user: user, arena_name: "test-name")

      conn =
        conn
        |> get("/users/#{user.username}/arenas/#{arena.name}")

      assert html_response(conn, 200) =~ "test-name"
    end

    test "A non existant arena triggers a 404", %{conn: conn, user: user} do
      conn = conn |> get("/users/#{user.username}/arenas/fake-arena")

      assert html_response(conn, 404) =~ "Arena (fake-arena) Not Found"
    end
  end

  describe "create" do
    test "creating requires login", %{conn: conn} do
      conn = post(conn, "/arenas", %{foo: :bar})
      assert redirected_to(conn, 302) =~ "/login"
    end

    test "you can create a arena", %{conn: conn, user: user} do
      conn =
        conn
        |> signin(user: user)
        |> post("/arenas", %{
          "arena" => %{"name" => "FOO", "game_type" => "robot_game", "robot_game_settings" => %{}}
        })

      url = redirected_to(conn, 302)
      %{"user" => username} = Regex.named_captures(~r/\/users\/(?<user>.*)\/arenas/, url)
      assert URI.encode_www_form(user.username) == username
    end

    test "creating a arena with the same name as an existing arena is an error", %{
      conn: conn,
      user: user
    } do
      {:ok, _arena} = robot_game_arena(user: user, arena_name: "FOO")

      conn =
        conn
        |> signin(user: user)
        |> post("/arenas", %{
          "arena" => %{"name" => "FOO", "game_type" => "robot_game", "robot_game_settings" => %{}}
        })

      assert html_response(conn, 200) =~ "has already been taken"
    end
  end

  describe "new" do
    test "It asks you the game type if you don't provide a game type", %{conn: conn, user: user} do
      conn =
        conn
        |> signin(user: user)
        |> get("/arenas/new")

      html = html_response(conn, 200)
      {:ok, document} = Floki.parse_document(html)

      game_types =
        Floki.find(document, "a")
        |> Enum.map(&Floki.attribute(&1, "a", "href"))
        |> List.flatten()
        |> Enum.filter(&String.starts_with?(&1, "/arenas/new"))
        |> Enum.map(fn "/arenas/new?game_type=" <> game_type -> game_type end)

      assert Enum.sort(game_types) == Enum.sort(installed_games() |> Enum.map(&"#{&1.name}"))
    end

    test "theres a form to create a new arena", %{conn: conn, user: user} do
      conn =
        conn
        |> signin(user: user)
        |> get("/arenas/new?game_type=robot_game")

      html = html_response(conn, 200)
      {:ok, document} = Floki.parse_document(html)
      assert [_form] = Floki.find(document, "form:not(#logout)")
    end
  end

  describe "index" do
    test "it will 404 if the user isn't found", %{conn: conn} do
      conn = get(conn, "/users/FAKE_username/arenas")
      assert html_response(conn, 404) =~ "User (FAKE_username) Not Found"
    end

    test "it will show a user's arenas", %{conn: conn, user: user} do
      for i <- [1, 2, 3] do
        {:ok, _} = robot_game_arena(user: user, arena_name: "test-name-#{i}")
      end

      conn = get(conn, "/users/#{user.username}/arenas")
      html = html_response(conn, 200)
      {:ok, document} = Floki.parse_document(html)

      assert ["Name: test-name-1", "Name: test-name-2", "Name: test-name-3"] =
               Enum.sort(Floki.find(document, ".arena .name") |> Enum.map(&Floki.text/1))
    end
  end

  describe "edit" do
    test "editing requires login", %{conn: conn} do
      conn = get(conn, "/users/some-username/arenas/fake-arena/edit")
      assert redirected_to(conn, 302) =~ "/login"
    end

    test "trying to edit a arena that doesn't exist is an error", %{conn: conn, user: user} do
      conn =
        conn
        |> signin(user: user)
        |> get("/users/#{user.username}/arenas/fake-arena/edit")

      html = html_response(conn, 404)
      assert html =~ "Arena (fake-arena) for User (#{user.username}) Not Found"
    end

    test "trying to edit someone else's arena is an error", %{conn: conn, user: user} do
      {:ok, arena} =
        Arena.changeset(%Arena{user_id: Ecto.UUID.generate(), name: "foo"}, %{
          "robot_game_settings" => %{}
        })
        |> Repo.insert()

      conn =
        conn
        |> signin(user: user)
        |> get("/users/#{user.username}/arenas/#{arena.name}/edit")

      html = html_response(conn, 404)
      assert html =~ "Arena (#{arena.name}) for User (#{user.username}) Not Found"
    end

    test "You can edit your own arena if it exists", %{user: user, conn: conn} do
      {:ok, arena} =
        user
        |> Ecto.build_assoc(:arenas)
        |> Arena.changeset(%{"name" => "foo", "robot_game_settings" => %{}})
        |> Repo.insert()

      conn =
        conn
        |> signin(user: user)
        |> get("/users/#{user.username}/arenas/#{arena.name}/edit")

      html = html_response(conn, 200)
      assert html =~ "Edit"
    end
  end

  describe "update" do
    test "updating requires login", %{conn: conn} do
      conn = put(conn, "/users/some-username/arenas/fake-arena", %{foo: "bar"})
      assert redirected_to(conn, 302) =~ "/login"
    end

    test "you can't update a arena that doesn't exist", %{conn: conn, user: user} do
      conn =
        conn
        |> signin(user: user)
        |> put("/users/#{user.username}/arenas/fake-arena", %{"arena" => %{foo: "bar"}})

      html = html_response(conn, 404)
      assert html =~ "Arena (fake-arena) for User (#{user.username}) Not Found"
    end

    test "trying to update someone else's arena is an error", %{conn: conn, user: user} do
      {:ok, arena} =
        Arena.changeset(%Arena{user_id: Ecto.UUID.generate(), name: "foo"}, %{
          "robot_game_settings" => %{}
        })
        |> Repo.insert()

      conn =
        conn
        |> signin(user: user)
        |> put("/users/#{user.username}/arenas/#{arena.name}", %{"arena" => %{"name" => "bar"}})

      html = html_response(conn, 404)
      assert html =~ "Arena (#{arena.name}) for User (#{user.username}) Not Found"
    end

    test "You can update your own arena if it exists", %{user: user, conn: conn} do
      {:ok, %{id: arena_id} = arena} =
        user
        |> Ecto.build_assoc(:arenas)
        |> Arena.changeset(%{"name" => "foo", "robot_game_settings" => %{}})
        |> Repo.insert()

      conn =
        conn
        |> signin(user: user)
        |> put("/users/#{user.username}/arenas/#{arena.name}", %{"arena" => %{"name" => "bar"}})

      assert redirected_to(conn, 302) == "/users/#{user.username}/arenas/bar"
      assert %{name: "bar"} = Repo.get(Arena, arena_id)
    end
  end
end
