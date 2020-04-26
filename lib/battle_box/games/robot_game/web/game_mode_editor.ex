defmodule BattleBox.Games.RobotGame.Web.GameModeEditor do
  use BattleBoxWeb, :live_view
  alias BattleBox.Games.RobotGame.{Settings, Web.RobotGameView}

  def mount(_params, _session, socket) do
    changeset = Settings.changeset(Settings.new())
    {:ok, assign(socket, changeset: changeset)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    RobotGameView.render("game_mode_editor.html", assigns)
  end
end
