defmodule BattleBox.GameEngine.Connection do
  alias BattleBox.{GameEngine, User}

  def authorize(game_engine, connection_id, user) do
    case get_by_id(game_engine, connection_id) do
      {:ok, pid} ->
        send(pid, {:auth, user})
        :ok

      {:error, :not_found} = err ->
        err
    end
  end

  def get_by_id(game_engine, connection_id) do
    connection_registry = GameEngine.names(game_engine).connection_registry

    case Registry.lookup(connection_registry, connection_id) do
      [] -> {:error, :not_found}
      [{pid, meta}] -> Map.merge(%{pid: pid}, meta)
    end
  end
end
