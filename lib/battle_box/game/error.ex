defprotocol BattleBox.Game.Error do
  def to_human(error)
  def level(error)
end

defmodule BattleBox.Game.Error.Timeout do
  defstruct []

  defimpl BattleBox.Game.Error do
    def level(_), do: :warn

    def to_human(_) do
      "You ran out of time!"
    end
  end
end
