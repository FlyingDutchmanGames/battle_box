defmodule BattleBoxWeb.Live.HumanPlayer do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.HumanView
  import BattleBox.InstalledGames, only: [game_type_name_to_module: 1]
  import BattleBox.GameEngine.HumanServer, only: [connect_ui: 1]
  import BattleBox.GameEngine, only: [get_human_server: 2]

  def mount(_params, %{"human_server_id" => human_server_id, "user_id" => user_id}, socket) do
    with {:hs, %{pid: _} = hs} <- {:hs, get_human_server(game_engine(), human_server_id)},
         {:connected?, true} <- {:connected?, connected?(socket)},
         {:connect, {:ok, game_info}} <- {:connect, connect_ui(hs.pid)} do
      Process.monitor(hs.pid)
      component = game_type_name_to_module(game_info.game_request.game_type).play_component()
      {:ok, assign(socket, human_server: hs, game_info: game_info, component: component)}
    else
      {:hs, nil} -> {:ok, assign(socket, not_found: true)}
      {:connected?, false} -> {:ok, assign(socket, connected?: false)}
      {:connect, {:error, :already_connected}} -> {:ok, assign(socket, already_connected: true)}
    end
  end

  def render(%{already_connected: true} = assigns), do: ~L"<h1>Already Connected</h1>"
  def render(%{connected?: false} = assigns), do: ~L"<h1>Connecting</h1>"
  def render(%{not_found: true} = assigns), do: ~L"<h1>Not Found</h1>"

  def render(assigns) do
    HumanView.render("_human_player.html", assigns)
  end
end
