defmodule BattleBoxWeb.GameLive do
  alias BattleBoxWeb.{PageView, RobotGameView}
  use BattleBoxWeb, :live_view
  alias BattleBox.GameEngine
  alias BattleBox.Games.RobotGame.Game

  def mount(%{"game_id" => game_id} = params, _session, socket) do
    if connected?(socket) do
      GameEngine.subscribe(game_engine(), "game:#{game_id}")
    end

    case get_game(game_id) do
      nil ->
        {:ok, assign(socket, :not_found, true)}

      game ->
        turn =
          case params["turn"] do
            nil -> game.turn
            turn when is_binary(turn) -> String.to_integer(turn)
          end

        {:ok, assign(socket, game: game, turn: turn)}
    end
  end

  def handle_params(params, _uri, %{assigns: %{game: game}} = socket) do
    turn =
      case params["turn"] do
        nil ->
          game.turn

        turn when is_binary(turn) ->
          turn = String.to_integer(turn)

          case turn do
            turn when turn < 0 -> 0
            turn -> turn
          end
      end

    {:noreply, assign(socket, :turn, turn)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def handle_event("change_turn", %{"code" => code}, socket)
      when code in ["ArrowRight", "ArrowLeft"] do
    turn =
      case code do
        "ArrowRight" -> socket.assigns.turn + 1
        "ArrowLeft" -> socket.assigns.turn - 1
      end

    {:noreply,
     push_patch(socket,
       to: Routes.live_path(socket, __MODULE__, socket.assigns.game.id, %{turn: turn})
     )}
  end

  def handle_event("change_turn", _, socket), do: {:noreply, socket}

  def handle_info({:game_update, id}, %{assigns: %{game: %{id: id}}} = socket) do
    game = get_game(id)
    {:noreply, assign(socket, game: game, turn: game.turn)}
  end

  def render(%{not_found: true}), do: PageView.render("not_found.html", message: "Game not found")
  def render(%{game: _} = assigns), do: RobotGameView.render("play.html", assigns)

  defp get_game(game_id) do
    case GameEngine.get_game(game_engine(), game_id) do
      nil -> Game.get_by_id_with_settings(game_id)
      %{game: game} -> game
    end
  end
end
