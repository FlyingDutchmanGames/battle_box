defmodule BattleBoxWeb do
  def live_view do
    quote do
      use Phoenix.LiveView
      alias BattleBoxWeb.Router.Helpers, as: Routes

      @endpoint BattleBoxWeb.Endpoint
      import BattleBox.GameEngine.Provider, only: [game_engine: 0]
    end
  end

  def controller do
    quote do
      import Phoenix.LiveView.Controller
      import BattleBoxWeb.Controllers.Helpers
      use Phoenix.Controller, namespace: BattleBoxWeb

      import Plug.Conn
      import BattleBoxWeb.Gettext
      alias BattleBoxWeb.Router.Helpers, as: Routes
      import Phoenix.LiveView.Controller
      import BattleBox.Utilities.Paginator, only: [paginate: 2, pagination_info: 1]

      import BattleBox.GameEngine.Provider, only: [game_engine: 0]
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/battle_box_web/templates",
        namespace: BattleBoxWeb

      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      use Phoenix.HTML

      import BattleBoxWeb.ErrorHelpers
      import BattleBoxWeb.Gettext
      alias BattleBoxWeb.Router.Helpers, as: Routes
      import Phoenix.LiveView.Helpers
      import BattleBox.Utilities.Humanize
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import BattleBoxWeb.Gettext
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
