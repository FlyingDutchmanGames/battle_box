defmodule BattleBox.Games.RobotGame.Web.RobotGameView do
  use Phoenix.View,
    root: "lib/battle_box/games/robot_game/web/templates",
    namespace: BattleBox.Games.RobotGame.Web

  import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

  use Phoenix.HTML
  import BattleBoxWeb.ErrorHelpers
  import BattleBoxWeb.Gettext
  alias BattleBoxWeb.Router.Helpers, as: Routes
  import Phoenix.LiveView.Helpers
  import BattleBox.Humanize
end
