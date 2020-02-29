defmodule BattleBox.GameEngine.PlayerServer.PlayerSupervisor do
  use DynamicSupervisor
  alias BattleBox.GameEngine.PlayerServer

  def start_link(%{names: names} = opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: names.player_supervisor)
  end

  def init(opts) do
    init_arg = Map.take(opts, [:names])
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [init_arg])
  end

  def start_player(player_supervisor, %{connection: _} = opts) do
    DynamicSupervisor.start_child(player_supervisor, {PlayerServer, opts})
  end

  def player_servers_with_connection_id(player_registry, connection_id) do
    Registry.select(player_registry, matches_connection_id(connection_id))
    |> Enum.map(fn {player_server_id, pid, attrs} ->
      Map.merge(attrs, %{player_server_id: player_server_id, pid: pid})
    end)
  end

  defp matches_connection_id(connection_id) do
    # :ets.fun2ms(fn {player_server_id, pid, attrs} when :erlang.map_get(:connection_id, attrs) == connection_id ->
    #  {player_server_id, pid, attrs}
    # end)

    [
      {{:"$1", :"$2", :"$3"}, [{:==, {:map_get, :connection_id, :"$3"}, {:const, connection_id}}],
       [{{:"$1", :"$2", :"$3"}}]}
    ]
  end
end
