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
      |> Bot.changeset(%{"name" => "test-name"})
      |> Repo.insert()

    conn = get(conn, "/users/#{user.username}/bots/#{bot.name}")

    assert html_response(conn, 200) =~ "test-name"
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

    %{"name" => name, "user" => username} =
      Regex.named_captures(~r/\/users\/(?<user>.*)\/bots\/(?<name>.*)/, redirected_to(conn, 302))

    assert URI.encode_www_form(user.username) == username
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

    assert html_response(conn, 200) =~ "Bot with that name already exists for your user"
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

  describe "index" do
    test "it will 404 if the user isn't found", %{conn: conn} do
      conn = get(conn, "/users/FAKE_username/bots")
      assert html_response(conn, 404) =~ "User (FAKE_username) not found"
    end

    test "it will show a user's bots", %{conn: conn, user: user} do
      for i <- [1, 2, 3] do
        {:ok, _} =
          user
          |> Ecto.build_assoc(:bots)
          |> Bot.changeset(%{name: "test-name-#{i}"})
          |> Repo.insert()
      end

      conn =
        conn
        |> get("/users/#{user.username}/bots")

      html = html_response(conn, 200)
      {:ok, document} = Floki.parse_document(html)

      assert ["Name: test-name-1", "Name: test-name-2", "Name: test-name-3"] =
               Enum.sort(Floki.find(document, ".bot .name") |> Enum.map(&Floki.text/1))
    end
  end
end
