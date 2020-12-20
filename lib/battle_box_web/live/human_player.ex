defmodule BattleBoxWeb.Live.HumanPlayer do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.HumanView
  import BattleBox.InstalledGames, only: [game_type_name_to_module: 1]
  import BattleBox.GameEngine.HumanServer, only: [connect_ui: 1, submit_commands: 2]
  import BattleBox.GameEngine, only: [get_human_server: 2]

  alias BattleBox.GameEngine.Message.{
    CommandsRequest,
    DebugInfo,
    GameInfo,
    GameOver,
    GameRequest,
    GameCanceled
  }

  def mount(_params, %{"human_server_id" => human_server_id, "user_id" => user_id}, socket) do
    with {:hs, %{pid: _} = hs} <- {:hs, get_human_server(game_engine(), human_server_id)},
         {:connected?, true} <- {:connected?, connected?(socket)},
         {:connect, {:ok, game_info}} <- {:connect, connect_ui(hs.pid)} do
      Process.monitor(hs.pid)
      game_module = game_type_name_to_module(game_info.game_request.game_type)
      {:ok, assign(socket, human_server: hs, game_info: game_info, game_module: game_module)}
    else
      {:hs, nil} -> {:ok, assign(socket, not_found: true)}
      {:connected?, false} -> {:ok, assign(socket, connected?: false)}
      {:connect, {:error, :already_connected}} -> {:ok, assign(socket, already_connected: true)}
    end
  end

  def handle_info(%GameInfo{} = gi, socket) do
    {:noreply, assign(socket, game_info: gi)}
  end

  def handle_info(%CommandsRequest{} = cr, socket) do
    {:noreply, assign(socket, commands_request: cr)}
  end

  def handle_info({:commands, commands}, socket) do
    :ok = submit_commands(socket.assigns.human_server.pid, commands)
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    IO.inspect(msg, label: "UNHANDLED MESSAGE")
    {:noreply, socket}
  end

  def render(%{already_connected: true} = assigns), do: ~L"<h1>Already Connected</h1>"
  def render(%{connected?: false} = assigns), do: ~L"<h1>Connecting</h1>"
  def render(%{not_found: true} = assigns), do: ~L"<h1>Not Found</h1>"

  def render(assigns) do
    HumanView.render("_human_player.html", assigns)
  end
end
