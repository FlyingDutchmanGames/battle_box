defmodule BattleBox.GameServer.GameSupervisor do
  use DynamicSupervisor
  alias BattleBox.GameServer

  def start_link(%{name: name} = opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: name)
  end

  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(game_supervisor, %{player_1: _, player_2: _, game: _} = opts) do
    DynamicSupervisor.start_child(game_supervisor, {GameServer, opts})
  end
end
