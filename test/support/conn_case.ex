defmodule BattleBoxWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      alias BattleBoxWeb.Router.Helpers, as: Routes
      import BattleBox.Test.DataHelpers
      alias BattleBox.Repo
      @endpoint BattleBoxWeb.Endpoint
      alias BattleBox.GameEngineProvider.Mock, as: GameEngineProvider
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(BattleBox.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(BattleBox.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
