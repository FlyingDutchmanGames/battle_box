defmodule BattleBoxWeb.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest

      @endpoint BattleBoxWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(BattleBox.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(BattleBox.Repo, {:shared, self()})
    end

    :ok
  end
end
