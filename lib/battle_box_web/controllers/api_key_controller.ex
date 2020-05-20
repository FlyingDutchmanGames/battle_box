defmodule BattleBoxWeb.ApiKeyController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Repo, ApiKey}
  import Ecto.Query, only: [from: 2]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def delete(%{assigns: %{user: user}} = conn, %{"id" => id}) do
    api_key = Repo.one(from api_key in ApiKey, where: api_key.user_id == ^user.id and api_key.id == ^id)
    {:ok, _key} = Repo.delete(api_key)
    redirect(conn, to: Routes.api_key_path(conn, :index))
  end

  def create(%{assigns: %{user: user}} = conn, %{"api_key" => params}) do
    {:ok, api_key} =
      user
      |> Ecto.build_assoc(:api_keys)
      |> ApiKey.changeset(params)
      |> Repo.insert()

    render(conn, "show.html", api_key: api_key)
  end

  def index(%{assigns: %{user: user}} = conn, _params) do
    user = Repo.preload(user, :api_keys)
    render(conn, "index.html", user: user)
  end
end
