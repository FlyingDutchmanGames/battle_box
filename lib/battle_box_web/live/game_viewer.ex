defmodule BattleBoxWeb.Live.GameViewer do
  alias BattleBox.{Repo, Game, GameEngine, GameEngine.GameServer}
  alias BattleBoxWeb.{GameView, PageView}
  use BattleBoxWeb, :live_view

  def mount(_params, %{"game_id" => game_id}, socket) do
    case get_game(game_id) do
      nil ->
        {:ok, assign(socket, :not_found, true)}

      {source, game} ->
        with {:live, pid} <- source,
             true <- connected?(socket) do
          GameEngine.subscribe_to_game_events(game_engine(), game_id, [:game_update])
          Process.monitor(pid)
        end

        {:ok, assign(socket, game: game, source: source)}
    end
  end

  def render(%{not_found: true, game_id: game_id}),
    do: PageView.render("not_found.html", message: "Game (#{game_id}) not found")

  def render(assigns) do
    GameView.render("_game_viewer.html", assigns)
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {game_source, game} = get_game(socket.assigns.game.id)
    {:noreply, assign(socket, game: game, game_source: game_source)}
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
