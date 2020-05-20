defmodule BattleBoxWeb.BotControllerTest do
  use BattleBoxWeb.ConnCase
  alias BattleBox.Bot

  @user_id Ecto.UUID.generate()

  test "you can view a bot", %{conn: conn} do
    bot =
      Bot.changeset(%Bot{}, %{
        name: "TEST_NAME",
        user_id: @user_id
      })
      |> Repo.insert!(returning: true)

    conn =
      conn
      |> signin(user_id: @user_id)
      |> get("/bots/#{bot.name}")

    assert html_response(conn, 200) =~ "TEST_NAME"
    assert html_response(conn, 200) =~ bot.token
  end

  test "trying to view a non existant bot is a not found 404", %{conn: conn} do
    conn = conn |> get("/bots/#{Ecto.UUID.generate()}")
    assert html_response(conn, 404) =~ "Not Found"
  end

  test "trying to create a bot without logging in redirects to the login page", %{conn: conn} do
    conn = post(conn, "/bots", %{"bot" => %{"name" => "FOO"}})
    assert "/login" <> id = redirected_to(conn, 302)
  end

  test "you can create a bot", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id)
      |> post("/bots", %{"bot" => %{"name" => "FOO"}})

    assert "/bots/" <> id = redirected_to(conn, 302)
    assert %Bot{user_id: @user_id} = Repo.get(Bot, id)
  end

  test "trying to create a bot with a name that exists is an error", %{conn: conn} do
    {:ok, user} = create_user(id: @user_id)

    {:ok, bot} =
      user
      |> Ecto.build_assoc(:bots)
      |> Bot.changeset(%{name: "TEST BOT"})
      |> Repo.insert()

    conn =
      conn
      |> signin(user_id: @user_id)
      |> post("/bots", %{"bot" => %{"name" => "FOO"}})

    assert html_response(conn, 200) =~ "has already been taken"
  end

  test "theres a form to create a new bot", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id)
      |> get("/bots/new")

    html = html_response(conn, 200)
    {:ok, document} = Floki.parse_document(html)
    assert [_form] = Floki.find(document, "form:not(#logout)")
  end
end
