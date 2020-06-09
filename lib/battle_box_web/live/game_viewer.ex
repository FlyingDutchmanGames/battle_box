defmodule BattleBoxWeb.Live.GameViewer do
  alias BattleBox.{Repo, Game, GameEngine, GameEngine.GameServer}
  alias BattleBoxWeb.{GameView, PageView}
  use BattleBoxWeb, :live_view

  def mount(_params, %{"game_id" => game_id} = session, socket) do
    socket = assign(socket, turn: String.to_integer(session["turn"] || "1"))

    case get_game(game_id) do
      nil ->
        {:ok, assign(socket, not_found: true, game_id: game_id)}

      {source, game} ->
        with {:live, pid} <- source,
             true <- connected?(socket) do
          GameEngine.subscribe_to_game_events(game_engine(), game_id, [:game_update])
          Process.monitor(pid)
        end

        {:ok, set_game(socket, game, source)}
    end
  end

  def handle_event("change-turn", event, socket) do
    case event do
      %{"turn" => turn} ->
        turn = String.to_integer(turn)
        {:noreply, assign(socket, turn: turn)}

      %{"code" => "ArrowRight"} ->
        {:noreply, update(socket, :turn, fn turn -> min(turn + 1, socket.assigns.max_turn) end)}

      %{"code" => "ArrowLeft"} ->
        {:noreply, update(socket, :turn, fn turn -> max(0, turn - 1) end)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info({_topic, :game_update, _game_id}, socket) do
    {source, game} = get_game(socket.assigns.game.id)
    {:noreply, set_game(socket, game, source)}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {source, game} = get_game(socket.assigns.game.id)
    {:noreply, set_game(socket, game, source)}
  end

  def render(%{not_found: true, game_id: game_id}) do
    PageView.render("not_found.html", message: "Game (#{game_id}) not found")
  end

  def render(assigns) do
    GameView.render("_game_viewer.html", assigns)
  end

  defp set_game(socket, game, source) do
    %{current_turn: current_turn, max_turn: max_turn} = Game.turn_info(game)

    socket = assign(socket, max_turn: max_turn, source: source)

    case source do
      {:live, _} ->
        turn = max(0, current_turn - 1)
        assign(socket, game: game, turn: turn, source: source)

      :historical ->
        assign(socket, game: game)
    end
  end

  defp get_game(game_id) do
    case GameEngine.get_game_server(game_engine(), game_id) do
      nil ->
        Game
        |> Repo.get(game_id)
        |> Game.preload_game_data()
        |> Repo.preload(lobby: [:user], game_bots: [bot: :user])
        |> case do
          nil -> nil
          game -> {:historical, Game.initialize(game)}
        end

      %{pid: pid} ->
        {:ok, game} = GameServer.get_game(pid)
        {{:live, pid}, game}
    end
  end
end
