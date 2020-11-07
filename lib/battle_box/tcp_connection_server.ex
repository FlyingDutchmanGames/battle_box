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
end
