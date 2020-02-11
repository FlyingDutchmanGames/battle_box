defmodule BattleBox.GameEngine do
  use Supervisor
  alias BattleBox.GameServer.GameSupervisor, as: GameSup
  alias BattleBox.PlayerServer.PlayerSupervisor, as: PlayerSup
  alias BattleBox.MatchMakerServer

  @default_name GameEngine
  def default_name, do: @default_name

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, @default_name)
    Supervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    name = Keyword.fetch!(opts, :name)

    children = [
      {Registry, keys: :unique, name: connection_registry_name(name)},
      {Registry, keys: :unique, name: player_registry_name(name)},
      {Registry, keys: :unique, name: game_registry_name(name)},
      {BattleBox.MatchMaker, %{names: names(name)}},
      {GameSup, %{names: names(name)}},
      {PlayerSup, %{names: names(name)}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_game(game_engine, opts),
    do: GameSup.start_game(game_supervisor_name(game_engine), opts)

  def start_player(game_engine, opts),
    do: PlayerSup.start_player(player_supervisor_name(game_engine), opts)

  def force_match_make(game_engine),
    do: MatchMakerServer.force_match_make(match_maker_server_name(game_engine))

  def names(name) do
    %{
      game_engine: name,
      game_registry: game_registry_name(name),
      game_supervisor: game_supervisor_name(name),
      player_registry: player_registry_name(name),
      player_supervisor: player_supervisor_name(name),
      match_maker: match_maker_name(name),
      match_maker_server: match_maker_server_name(name),
      match_maker_registry: match_maker_registry_name(name),
      connection_registry: connection_registry_name(name)
    }
  end

  defp game_registry_name(name), do: Module.concat(name, GameRegistry)
  defp game_supervisor_name(name), do: Module.concat(name, GameSupervisor)
  defp player_registry_name(name), do: Module.concat(name, PlayerRegistry)
  defp player_supervisor_name(name), do: Module.concat(name, PlayerSupervisor)
  defp match_maker_name(name), do: Module.concat(name, MatchMaker)
  defp match_maker_server_name(name), do: Module.concat(name, MatchMaker.MatchMakerServer)
  defp match_maker_registry_name(name), do: Module.concat(name, MatchMaker.Registry)
  defp connection_registry_name(name), do: Module.concat(name, Connection.Registry)
end
