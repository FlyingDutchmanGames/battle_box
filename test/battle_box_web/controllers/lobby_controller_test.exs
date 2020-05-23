defmodule BattleBoxWeb.LobbyControllerTest do
  use BattleBoxWeb.ConnCase, async: false

  @user_id Ecto.UUID.generate()

  setup do
    {:ok, user} = create_user(id: @user_id)
    %{user: user}
  end

  test "you can view a lobby", %{conn: conn, user: user} do
    {:ok, lobby} = robot_game_lobby(user: user, lobby_name: "TEST_NAME")

    conn =
      conn
      |> signin(user: user)
      |> get("/lobbies/#{lobby.name}")

    assert html_response(conn, 200) =~ "TEST_NAME"
  end

  test "you can create a lobby", %{conn: conn, user: user} do
    conn =
      conn
      |> signin(user: user)
      |> post("/lobbies", %{"lobby" => %{"name" => "FOO", "game_type" => "robot_game"}})

    url = redirected_to(conn, 302)
    %{"user" => user_name} = Regex.named_captures(~r/\/users\/(?<user>.*)\/lobbies/, url)
    assert URI.encode_www_form(user.user_name) == user_name
  end

  test "creating a lobby with the same name as an existing lobby is an error", %{
    conn: conn,
    user: user
  } do
    {:ok, _lobby} = robot_game_lobby(user: user, lobby_name: "FOO")

    conn =
      conn
      |> signin(user: user)
      |> post("/lobbies", %{"lobby" => %{"name" => "FOO", "game_type" => "robot_game"}})

    assert html_response(conn, 200) =~ "has already been taken"
  end

  test "theres a form to create a new lobby", %{conn: conn, user: user} do
    conn =
      conn
      |> signin(user: user)
      |> get("/lobbies/new")

    html = html_response(conn, 200)
    {:ok, document} = Floki.parse_document(html)
    assert [_form] = Floki.find(document, "form:not(#logout)")
  end

  describe "lobbies index" do
    test "it will 404 if the user isn't found", %{conn: conn} do
      conn = get(conn, "/users/FAKE_USER_NAME/lobbies")
      assert html_response(conn, 404) =~ "User (FAKE_USER_NAME) not found"
    end

    test "it will show a user's lobbies", %{conn: conn, user: user} do
      for i <- [1, 2, 3] do
        {:ok, _} = robot_game_lobby(user: user, lobby_name: "TEST_NAME#{i}")
      end

      conn =
        conn
        |> get("/users/#{user.user_name}/lobbies")

      html = html_response(conn, 200)
      {:ok, document} = Floki.parse_document(html)

      assert ["Name: TEST_NAME1", "Name: TEST_NAME2", "Name: TEST_NAME3"] =
               Enum.sort(Floki.find(document, ".lobby .name") |> Enum.map(&Floki.text/1))
    end
  end
end
