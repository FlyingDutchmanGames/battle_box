defmodule BattleBoxWeb.LobbyControllerTest do
  use BattleBoxWeb.ConnCase
  alias BattleBox.Lobby

  @user_id Ecto.UUID.generate()

  test "you can view a lobby", %{conn: conn} do
    lobby =
      Lobby.changeset(%Lobby{}, %{
        name: "TEST_NAME",
        user_id: @user_id,
        game_type: "robot_game"
      })
      |> Repo.insert!(returning: true)

    conn =
      conn
      |> signin(user_id: @user_id)
      |> get("/lobbies/#{lobby.id}")

    assert html_response(conn, 200) =~ "TEST_NAME"
  end

  test "you can create a lobby", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id)
      |> post("/lobbies", %{"lobby" => %{"name" => "FOO"}})

    assert "/lobbies/" <> id = redirected_to(conn, 302)
    assert %Lobby{user_id: @user_id} = Lobby.get_by_id(id)
  end

  test "creating a lobby with the same name as an existing lobby is an error", %{conn: conn} do
    Lobby.changeset(%Lobby{}, %{name: "FOO", user_id: @user_id, game_type: "robot_game"})
    |> Repo.insert!()

    conn =
      conn
      |> signin(user_id: @user_id)
      |> post("/lobbies", %{"lobby" => %{"name" => "FOO"}})

    assert html_response(conn, 200) =~ "has already been taken"
  end

  test "theres a form to create a new lobby", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id)
      |> get("/lobbies/new")

    html = html_response(conn, 200)
    {:ok, document} = Floki.parse_document(html)
    assert [_form] = Floki.find(document, "form")
  end

  describe "lobbies index" do
    test "it will show a user's lobbies", %{conn: conn} do
      for i <- [1, 2, 3] do
        Repo.insert!(%Lobby{
          name: "TEST_NAME#{i}",
          user_id: @user_id,
          game_type: BattleBox.Games.RobotGame.Game
        })
      end

      conn =
        conn
        |> signin(user_id: @user_id)
        |> get("/users/#{@user_id}/lobbies")

      html = html_response(conn, 200)
      {:ok, document} = Floki.parse_document(html)

      assert ["Name: TEST_NAME1", "Name: TEST_NAME2", "Name: TEST_NAME3"] =
               Floki.find(document, ".lobby .name") |> Enum.map(&Floki.text/1)
    end
  end
end
