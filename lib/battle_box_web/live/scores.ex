defmodule BattleBoxWeb.Live.Scores do
  use BattleBoxWeb, :live_view
  alias BattleBox.{GameEngine, Lobby}
  alias BattleBoxWeb.LobbyView

  def mount(_params, %{"lobby" => lobby}, socket) do
    if connected?(socket) do
      GameEngine.subscribe_to_lobby_events(game_engine(), lobby.id, [
        :game_start,
        :game_update
      ])
    end

    games = GameEngine.get_live_games_with_lobby_id(game_engine(), lobby.id)

    if connected?(socket) do
      for %{pid: pid} <- games, do: Process.monitor(pid)
    end
    
    {:ok, assign(socket, games: games)}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, socket) do
    games = Enum.reject(socket.assigns.games, &(&1.pid == pid))
    {:noreply, assign(socket, :games, games)}
  end

  def handle_info({:game_start, game_id}, socket) do
    games =
      case GameEngine.get_game_server(game_engine(), game_id) do
        nil ->
          socket.assigns.games

        game ->
          Process.monitor(game.pid)
          [game | socket.assigns.games]
      end

    {:noreply, assign(socket, :games, games)}
  end

  def handle_info({:game_update, game_id}, socket) do
    game = GameEngine.get_game_server(game_engine(), game_id)

    games =
      Enum.map(socket.assigns.games, fn
        %{game_id: ^game_id} -> game
        other_game -> other_game
      end)

    {:noreply, assign(socket, :games, games)}
  end


  def render(assigns) do
    LobbyView.render("_live_scores.html", assigns)
  end
end

