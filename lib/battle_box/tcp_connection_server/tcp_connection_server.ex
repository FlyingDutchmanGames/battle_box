defmodule BattleBox.TcpConnectionServer do
  alias __MODULE__.ConnectionHandler

  @default_name TcpConnectionServer

  def child_spec(opts) do
    port = Keyword.fetch!(opts, :port)
    game_engine = Keyword.get(opts, :game_engine, GameEngine)
    name = Keyword.get(opts, :name, @default_name)

    :ranch.child_spec(
      name,
      :ranch_tcp,
      [port: port],
      ConnectionHandler,
      game_engine: game_engine
    )
  end
end
