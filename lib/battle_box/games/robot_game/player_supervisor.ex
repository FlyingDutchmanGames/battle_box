defmodule BattleBox.Games.RobotGame.PlayerSupervisor do
  use DynamicSupervisor

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    DynamicSupervisor.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [
        %{
          matchmaker: opts[:matchmaker]
        }
      ]
    )
  end
end
