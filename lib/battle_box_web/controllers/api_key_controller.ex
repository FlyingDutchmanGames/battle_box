defmodule BattleBoxWeb.ApiKeyController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Repo, ApiKey}
  import Ecto.Query, only: [from: 2]

  def new(conn, _params) do
    changeset = ApiKey.changeset(%ApiKey{})
    render(conn, "new.html", changeset: changeset)
  end

  def delete(%{assigns: %{current_user: user}} = conn, %{"id" => id}) do
    api_key =
      Repo.one(from api_key in ApiKey, where: api_key.user_id == ^user.id and api_key.id == ^id)

    {:ok, _key} = Repo.delete(api_key)
    redirect(conn, to: Routes.api_key_path(conn, :index))
  end

  def create(%{assigns: %{current_user: user}} = conn, %{"api_key" => params}) do
    user
    |> Ecto.build_assoc(:api_keys)
    |> ApiKey.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, api_key} -> render(conn, "show.html", api_key: api_key)
      {:error, changeset} -> render(conn, "new.html", changeset: changeset)
    end
  end

  def index(%{assigns: %{current_user: user}} = conn, _params) do
    nav_segments = [conn.assigns.current_user, {"Keys", Routes.api_key_path(conn, :index)}]
    nav_options = [{:new, :api_key}]
    user = Repo.preload(user, :api_keys)
    render(conn, "index.html", nav_segments: nav_segments, nav_options: nav_options, user: user)
  end
end
