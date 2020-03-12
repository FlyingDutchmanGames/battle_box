defmodule BattleBox.TcpConnectionServer do
  alias __MODULE__.ConnectionHandler
  alias BattleBox.GameEngine

  @default_name TcpConnectionServer

  def child_spec(opts) do
    port = Keyword.fetch!(opts, :port)
    name = Keyword.get(opts, :name, @default_name)

    names =
      Keyword.get(opts, :game_engine, GameEngine.default_name())
      |> GameEngine.names()

    :ranch.child_spec(
      name,
      :ranch_tcp,
      [port: port],
      ConnectionHandler,
      %{names: names}
    )
  end

  def get_connections_with_user_id(game_engine, user_id) do
    connection_registry = GameEngine.names(game_engine).connection_registry
    Registry.select(connection_registry, matches_user_id(user_id))
    |> Enum.map(fn {connection_id, pid, attrs} ->
      Map.merge(attrs, %{connection_id: connection_id, pid: pid})
    end)
  end

  defp matches_user_id(connection_id) do
    [
      {{:"$1", :"$2", :"$3"}, [{:==, {:map_get, :user_id, :"$3"}, {:const, connection_id}}],
       [{{:"$1", :"$2", :"$3"}}]}
    ]
  end
end
