defmodule BattleBox.Games.Marooned.Ais.WildCard do
  def name, do: "wild-card"
  def description, do: "Does everything randomly"
  def difficulty, do: 1
  def creator, do: "the-notorious-gjp"

  def initialize(_settings) do
    :ok
  end

  def commands(_commands) do
    %{}
  end
end
