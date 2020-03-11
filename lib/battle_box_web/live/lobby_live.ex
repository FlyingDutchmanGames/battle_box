defmodule BattleBoxWeb.LobbyLive do
  use BattleBoxWeb, :live_view
  alias BattleBox.{GameEngine, Lobby, Repo}
  alias BattleBoxWeb.{LobbyView, PageView}

  def mount(%{"lobby_id" => lobby_id}, _session, socket) do
    lobby =
      Lobby.get_by_id(lobby_id)
      |> Repo.preload(:user)

    case lobby do
      nil ->
        {:ok, assign(socket, :not_found, true)}

      lobby ->
        GameEngine.subscribe_to_lobby_events(game_engine(), lobby_id, [
          :game_start,
          :game_update
        ])

        live_games = GameEngine.get_live_games_with_lobby_id(game_engine(), lobby.id)
        for %{pid: pid} <- live_games, do: Process.monitor(pid)
        {:ok, assign(socket, lobby: lobby, live_games: live_games)}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, socket) do
    live_games = Enum.reject(socket.assigns.live_games, &(&1.pid == pid))
    {:noreply, assign(socket, :live_games, live_games)}
  end

  def handle_info({:game_start, game_id}, socket) do
    live_games =
      case GameEngine.get_game_server(game_engine(), game_id) do
        nil ->
          socket.assigns.live_games

        game ->
          Process.monitor(game.pid)
          [game | socket.assigns.live_games]
      end

    {:noreply, assign(socket, :live_games, live_games)}
  end

  def handle_info({:game_update, game_id}, socket) do
    game = GameEngine.get_game_server(game_engine(), game_id)

    live_games =
      Enum.map(socket.assigns.live_games, fn
        %{game_id: ^game_id} -> game
        other_game -> other_game
      end)

    {:noreply, assign(socket, :live_games, live_games)}
  end

  def render(%{not_found: true}) do
    PageView.render("not_found.html", message: "Lobby not found")
  end

  def render(assigns) do
    LobbyView.render("lobby.html", assigns)
  end
end
