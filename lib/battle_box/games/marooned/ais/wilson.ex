defmodule BattleBox.Games.Marooned.Ais.Wilson do
  def name, do: "wilson"
  def description, do: "Tries to stay close to you"
  def difficulty, do: 3
  def creator, do: "the-notorious-gjp"

  def initialize(_settings) do
    :ok
  end

  def commands(_commands) do
    %{}
  end
end
