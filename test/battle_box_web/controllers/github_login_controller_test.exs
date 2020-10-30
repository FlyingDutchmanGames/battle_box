defmodule BattleBoxWeb.GithubLoginControllerTest do
  use BattleBoxWeb.ConnCase
  alias BattleBox.User

  import Tesla.Mock

  test "GET /auth/github/login", %{conn: conn} do
    conn = get(conn, "/auth/github/login")
    assert "https://github.com/login/oauth/authorize?" <> params = redirected_to(conn, 302)

    assert %{
             "client_id" => "TEST_GITHUB_CLIENT_ID",
             "redirect_uri" => "http://localhost:4002/auth/github/callback",
             "state" => state
           } = URI.decode_query(params)

    assert String.length(state) == 64
  end

  test "if you give it an invalid state it fails", %{conn: conn} do
    params =
      URI.encode_query(%{
        "state" => "invalid",
        "code" => "test code"
      })

    assert_raise(MatchError, "no match of right hand side value: false", fn ->
      get(conn, "/auth/github/callback?" <> params)
    end)
  end

  describe "github auth callback" do
    test "it calls out to github to get the oauth token and user", %{conn: conn} do
      mock(fn
        %{method: :post, url: "https://github.com/login/oauth/access_token", body: body} ->
          assert %{
                   "code" => "test code",
                   "state" => "test state",
                   "client_id" => "TEST_GITHUB_CLIENT_ID",
                   "client_secret" => "TEST_GITHUB_CLIENT_SECRET"
                 } = Jason.decode!(body)

          json(%{
            "access_token" => "access_token",
            "token_type" => "bearer"
          })

        %{method: :get, url: "https://api.github.com/user", headers: headers} ->
          assert Enum.find(headers, fn
                   {"authorization", "token access_token"} -> true
                   _ -> false
                 end)

          json(%{
            "avatar_url" => "https://avatars0.githubusercontent.com/u/16196910?v=4",
            "html_url" => "https://github.com/GrantJamesPowell",
            "id" => 1234,
            "login" => "GrantJamesPowell",
            "name" => "Grant Powell"
          })
      end)

      params =
        URI.encode_query(%{
          "state" => "test state",
          "code" => "test code"
        })

      conn =
        conn
        |> init_test_session(token: "foo")
        |> put_session(:github_auth_state, "test state")
        |> get("/auth/github/callback?#{params}")

      assert redirected_to(conn, 302) =~ "/"
      assert %User{} = Repo.get_by(User, github_id: 1234)
      assert get_session(conn, :github_auth_state) == nil
    end
  end
end
