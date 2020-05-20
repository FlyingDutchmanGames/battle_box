defmodule BattleBoxWeb.ApiKeyController do
  use BattleBoxWeb, :controller
  alias BattleBox.{Repo, ApiKey}

  def index(%{assigns: %{user: user}} = conn, _params) do
    user = Repo.preload(user, :api_keys)
    render(conn, "index.html", user: user)
  end
end
