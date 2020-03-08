defmodule BattleBoxWeb.LobbyLive do
  use BattleBoxWeb, :live_view
  alias BattleBox.{Lobby, Repo}
  alias BattleBoxWeb.{LobbyView, PageView}

  def mount(%{"lobby_id" => lobby_id}, _session, socket) do
    lobby =
      Lobby.get_by_id(lobby_id)
      |> Repo.preload(:user)

    case lobby do
      nil ->
        {:ok, assign(socket, :not_found, true)}

      lobby ->
        {:ok, assign(socket, :lobby, lobby)}
    end
  end

  def render(%{not_found: true}) do
    PageView.render("not_found.html", message: "Lobby not found")
  end

  def render(assigns) do
    LobbyView.render("lobby.html", assigns)
  end
end
