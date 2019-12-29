defmodule BattleBox.Games.RobotGame.RobotGameSupervisor do
  alias BattleBox.Games.RobotGame.GameSupervisor, as: GameSup
  alias BattleBox.Games.RobotGame.PlayerSupervisor, as: PlayerSup
  use Supervisor

  @default_name RobotGame

  def start_link(opts) do
    name = opts[:name] || @default_name
    Supervisor.start_link(__MODULE__, %{name: name}, name: name)
  end

  @impl true
  def init(%{name: name}) do
    children = [
      {GameSup, name: game_supervisor_name(name)},
      {PlayerSup, name: player_supervisor_name(name)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def game_supervisor_name(name), do: Module.concat(name, GameSupervisor)
  def player_supervisor_name(name), do: Module.concat(name, PlayerSupervisor)
end
