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
      |> get("/bots/#{bot.id}")

    assert html_response(conn, 200) =~ "TEST_NAME"
    assert html_response(conn, 200) =~ bot.token
  end

  test "you can create a bot", %{conn: conn} do
    conn =
      conn
      |> signin(user_id: @user_id)
      |> post("/bots", %{"bot" => %{"name" => "FOO"}})

    assert "/bots/" <> id = redirected_to(conn, 302)
    assert %Bot{user_id: @user_id} = Bot.get_by_id(id)
  end

  test "trying to create a bot with a name that exists is an error", %{conn: conn} do
    Bot.changeset(%Bot{}, %{name: "FOO", user_id: @user_id}) |> Repo.insert!()

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
    assert [_form] = Floki.find(document, "form")
  end
end
