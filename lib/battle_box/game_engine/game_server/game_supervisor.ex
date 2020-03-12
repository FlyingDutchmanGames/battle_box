defmodule BattleBox.GameEngine.GameServer.GameSupervisor do
  use DynamicSupervisor
  alias BattleBox.{GameEngine, GameEngine.GameServer}

  @select_all [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}]

  def start_link(%{names: names} = opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: names.game_supervisor)
  end

  def init(opts) do
    init_arg = Map.take(opts, [:names])
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [init_arg])
  end

  def start_game(game_engine, %{players: _, game: _} = opts) do
    game_supervisor = GameEngine.names(game_engine).game_supervisor
    DynamicSupervisor.start_child(game_supervisor, {GameServer, opts})
  end

  def get_live_games_with_lobby_id(game_engine, lobby_id) do
    game_registry = GameEngine.names(game_engine).game_registry
    select_from_registry(game_registry, select_games_with_lobby_id(lobby_id))
  end

  def get_live_games(game_engine) do
    game_registry = GameEngine.names(game_engine).game_registry
    select_from_registry(game_registry, @select_all)
  end

  defp select_games_with_lobby_id(lobby_id) do
    [
      {{:"$1", :"$2", :"$3"},
       [{:==, {:map_get, :id, {:map_get, :lobby, {:map_get, :game, :"$3"}}}, lobby_id}],
       [{{:"$1", :"$2", :"$3"}}]}
    ]
  end

  defp select_from_registry(registry, match_spec) do
    Registry.select(registry, match_spec)
    |> Enum.map(fn {game_id, pid, attrs} ->
      Map.merge(attrs, %{game_id: game_id, pid: pid})
    end)
  end
end
