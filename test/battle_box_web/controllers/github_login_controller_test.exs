defmodule BattleBoxWeb.GithubLoginControllerTest do
  use BattleBoxWeb.ConnCase
  alias BattleBox.User

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

    assert_raise(RuntimeError, "Invalid state param in github callback", fn ->
      get(conn, "/auth/github/callback?" <> params)
    end)
  end

  describe "github auth callback" do
    setup do
      bypass = Bypass.open()
      {:ok, bypass: bypass}
    end

    test "it calls out to github to get the oauth token and user", %{conn: conn, bypass: bypass} do
      Process.put(:bypass, endpoint_url(bypass.port))

      params =
        URI.encode_query(%{
          "state" => "test state",
          "code" => "test code"
        })

      Bypass.expect(bypass, fn
        %{request_path: "/login/oauth/access_token", method: "POST"} = conn ->
          {:ok, body, conn} = Plug.Conn.read_body(conn)

          assert %{
                   "code" => "test code",
                   "state" => "test state",
                   "client_id" => "TEST_GITHUB_CLIENT_ID",
                   "client_secret" => "TEST_GITHUB_CLIENT_SECRET"
                 } = Jason.decode!(body)

          conn
          |> put_resp_header("content-type", "application/json")
          |> resp(
            200,
            Jason.encode!(%{
              "access_token" => "access_token",
              "token_type" => "bearer"
            })
          )

        %{request_path: "/user", method: "GET"} = conn ->
          assert [] == get_req_header(conn, "Authorization")

          conn
          |> put_resp_header("content-type", "application/json")
          |> resp(
            200,
            Jason.encode!(%{
              "avatar_url" => "https://avatars0.githubusercontent.com/u/16196910?v=4",
              "html_url" => "https://github.com/GrantJamesPowell",
              "id" => 1234,
              "login" => "GrantJamesPowell",
              "name" => "Grant Powell"
            })
          )
      end)

      conn =
        conn
        |> init_test_session(token: "foo")
        |> put_session(:github_auth_state, "test state")
        |> get("/auth/github/callback?#{params}")

      assert redirected_to(conn, 302) =~ "/"
      assert %User{} = User.get_by_github_id(1234)
      assert get_session(conn, :github_auth_state) == nil
    end
  end

  defp endpoint_url(port), do: "http://localhost:#{port}"
end
