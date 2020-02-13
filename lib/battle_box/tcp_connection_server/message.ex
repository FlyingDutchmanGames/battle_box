defmodule BattleBox.TcpConnectionServer.Message do
  def encode_error(error_msg), do: encode(%{error: error_msg})
  def encode(msg), do: Jason.encode!(msg) <> "\n"
end
