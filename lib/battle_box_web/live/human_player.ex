defmodule BattleBoxWeb.Live.HumanPlayer do
  use BattleBoxWeb, :live_view
  alias BattleBoxWeb.HumanView
  alias BattleBox.{GameEngine, GameEngine.HumanServer}

  def mount(_params, %{"human_server_id" => human_server_id, "user_id" => user_id}, socket) do
    with {:hs, %{pid: hs_pid} = hs} <-
           {:hs, GameEngine.get_human_server(game_engine(), human_server_id)},
         {:connected?, true} <- {:connected?, connected?(socket)},
         {:connect, {:ok, game_info}} <- {:connect, HumanServer.connect_ui(hs_pid)} do
      {:ok, assign(socket, human_server: hs, game_info: game_info)}
    else
      {:hs, nil} -> {:ok, assign(socket, not_found: true)}
      {:connected?, false} -> {:ok, assign(socket, connected?: false)}
      {:connect, {:error, :already_connected}} -> {:ok, assign(socket, already_connected: true)}
    end
  end

  def render(%{already_connected: true} = assigns) do
    ~L"<h1>Already Connected</h1>"
  end

  def render(%{connected?: false} = assigns) do
    ~L"<h1>Connecting</h1>"
  end

  def render(%{not_found: true} = assigns) do
    ~L"<h1>Not Found</h1>"
  end

  def render(assigns) do
    HumanView.render("_human_player.html", assigns)
  end
end
