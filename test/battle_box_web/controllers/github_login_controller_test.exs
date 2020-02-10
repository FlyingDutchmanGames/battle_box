defmodule BattleBoxWeb.GithubLoginControllerTest do
  use BattleBoxWeb.ConnCase

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

  describe "github auth callback" do
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
  end
end
