defmodule BattleBoxWeb.Game do
  alias BattleBoxWeb.{PageView, RobotGameView}
  use BattleBoxWeb, :live_view
  alias BattleBox.{Repo, Game, GameEngine, GameEngine.GameServer}

  def mount(%{"game_id" => game_id} = params, _session, socket) do
    case get_game(game_id) do
      nil ->
        {:ok, assign(socket, :not_found, true)}

      {game_source, game} ->
        if connected?(socket) do
          GameEngine.subscribe_to_game_events(game_engine(), game_id, [:game_update])

          case game_source do
            {:live, pid} -> Process.monitor(pid)
            _ -> :ok
          end
        end

        {:ok,
         assign(
           socket,
           game: game,
           follow: params["follow"],
           turn: box_turn_number(game, params["turn"]),
           game_source: game_source
         )}
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

  def handle_info({_topic, :game_update, id}, %{assigns: %{game: %{id: id}}} = socket) do
    {game_source, game} = get_game(id)

    {:noreply,
     assign(socket, game: game, turn: game.robot_game.turn - 1, game_source: game_source)}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {game_source, game} = get_game(socket.assigns.game.id)

    {:noreply, assign(socket, game: game, turn: game.robot_game.turn, game_source: game_source)}
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
    case GameEngine.get_game_server(game_engine(), game_id) do
      nil ->
        result =
          Repo.get(Game, game_id)
          |> Repo.preload([:robot_game, game_bots: [bot: :user]])

        case result do
          nil -> nil
          game -> {:historical, Game.initialize(game)}
        end

      %{pid: pid} ->
        {:ok, game} = GameServer.get_game(pid)
        {{:live, pid}, game}
    end
  end
end
