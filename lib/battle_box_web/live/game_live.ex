defmodule BattleBoxWeb.GameLive do
  alias BattleBoxWeb.{PageView, RobotGameView}
  use BattleBoxWeb, :live_view
  alias BattleBox.{Repo, Game, GameEngine}

  def mount(%{"game_id" => game_id} = params, _session, socket) do
    if connected?(socket) do
      GameEngine.subscribe(game_engine(), "game:#{game_id}")
    end

    case get_game(game_id) do
      nil ->
        {:ok, assign(socket, :not_found, true)}

      game ->
        turn = box_turn_number(game, params["turn"])
        {:ok, assign(socket, game: game, turn: turn)}
    end
  end

  def handle_params(params, _uri, %{assigns: %{game: game}} = socket) do
    turn = box_turn_number(game, params["turn"])
    {:noreply, assign(socket, :turn, turn)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def handle_event(
        "change_turn",
        %{"code" => code},
        %{assigns: %{turn: current_turn, game: game}} = socket
      )
      when code in ["ArrowRight", "ArrowLeft"] do
    turn =
      case code do
        "ArrowRight" -> current_turn + 1
        "ArrowLeft" -> current_turn - 1
      end

    turn = box_turn_number(game, turn)

    {:noreply,
     push_patch(socket,
       to: Routes.live_path(socket, __MODULE__, game.id, %{turn: turn})
     )}
  end

  def handle_event("change_turn", _event, socket) do
    {:noreply, socket}
  end

  def handle_info({:game_update, id}, %{assigns: %{game: %{id: id}}} = socket) do
    game = get_game(id)
    {:noreply, assign(socket, game: game, turn: game.robot_game.turn)}
  end

  def render(%{not_found: true}), do: PageView.render("not_found.html", message: "Game not found")
  def render(%{game: _} = assigns), do: RobotGameView.render("play.html", assigns)

  defp box_turn_number(game, turn) when is_binary(turn),
    do: box_turn_number(game, String.to_integer(turn))

  defp box_turn_number(%{robot_game: %{turn: game_turn}}, nil), do: game_turn

  defp box_turn_number(%{robot_game: %{turn: game_turn}}, turn) when turn > game_turn,
    do: game_turn

  defp box_turn_number(_, turn) when turn < 0, do: 0
  defp box_turn_number(_, turn), do: turn

  defp get_game(game_id) do
    case GameEngine.get_game(game_engine(), game_id) do
      nil ->
        game =
          Game.get_by_id(game_id)
          |> Repo.preload(robot_game: [:settings], game_bots: [bot: :user])

        if not is_nil(game), do: update_in(game.robot_game, &BattleBoxGame.initialize/1)

      %{game: game} ->
        game
    end
  end
end
