defmodule BattleBoxWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ConnTest
      alias BattleBoxWeb.Router.Helpers, as: Routes

      @endpoint BattleBoxWeb.Endpoint
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
