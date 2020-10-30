defmodule BattleBox.Utilities.Github do
  use Tesla

  @type access_token :: binary()

  @github "https://github.com"
  @github_api "https://api.github.com"

  plug Tesla.Middleware.Headers, [
    {"user-agent", "botskrieg"},
    {"accept", "application/json"}
  ]

  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.KeepRequest

  @spec token_exchange(code :: binary(), state :: binary()) ::
          {:ok, access_token} | {:error, :bad_verification_code}
  def token_exchange(code, state) do
    post(@github <> "/login/oauth/access_token", %{
      client_id: Keyword.fetch!(config(), :client_id),
      client_secret: Keyword.fetch!(config(), :client_secret),
      code: code,
      state: state
    })
    |> case do
      {:ok, %Tesla.Env{status: 200, body: %{"access_token" => access_token}}} ->
        {:ok, access_token}

      {:ok, %Tesla.Env{status: 200, body: %{"error" => "bad_verification_code"}}} ->
        {:error, :bad_verification_code}
    end
  end

  @spec get_user(access_token :: access_token) :: {:ok, map()}
  def get_user(access_token) do
    get(@github_api <> "/user", headers: [{"authorization", "token #{access_token}"}])
    |> case do
      {:ok, %Tesla.Env{status: 200, body: user}} ->
        {:ok, user}
    end
  end

  defp config do
    Application.fetch_env!(:battle_box, :github)
  end
end
