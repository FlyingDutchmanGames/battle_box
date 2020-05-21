defmodule BattleBoxWeb.BotControllerTest do
  use BattleBoxWeb.ConnCase
  alias BattleBox.Bot

  @user_id Ecto.UUID.generate()

  setup do
    {:ok, user} = create_user(id: @user_id)
    %{user: user}
  end

  test "you can view a bot", %{conn: conn, user: user} do
    {:ok, bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{"name" => "TEST_NAME"})
      |> Repo.insert()

    conn = get(conn, "/users/#{@user_id}/bots/#{bot.name}")

    assert html_response(conn, 200) =~ "TEST_NAME"
  end

  test "trying to view a non existant bot is a not found 404", %{conn: conn} do
    conn = conn |> get("/users/#{@user_id}/bots/non-sense-name")
    assert html_response(conn, 404) =~ "Not Found"
  end

  test "trying to create a bot without logging in redirects to the login page", %{conn: conn} do
    conn = post(conn, "/bots", %{"bot" => %{"name" => "FOO"}})
    assert "/login" <> id = redirected_to(conn, 302)
  end

  test "you can create a bot", %{conn: conn, user: user} do
    conn =
      conn
      |> signin(user: user)
      |> post("/bots", %{"bot" => %{"name" => "FOO"}})

    assert "/users/" <> @user_id <> "/bots/" <> name = redirected_to(conn, 302)
    assert %Bot{} = Repo.get_by(Bot, name: name, user_id: @user_id)
  end

  test "trying to create a bot with a name that exists is an error", %{conn: conn, user: user} do
    {:ok, _bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "FOO"})
      |> Repo.insert()

    conn =
      conn
      |> signin(user: user)
      |> post("/bots", %{"bot" => %{"name" => "FOO"}})

    assert html_response(conn, 200) =~ "has already been taken"
  end

  test "theres a form to create a new bot", %{conn: conn, user: user} do
    conn =
      conn
      |> signin(user: user)
      |> get("/bots/new")

    html = html_response(conn, 200)
    {:ok, document} = Floki.parse_document(html)
    assert [_form] = Floki.find(document, "form:not(#logout)")
  end
end
