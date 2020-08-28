defmodule BattleBox.Utilities.Grid do
  def manhattan_distance([x1, y1], [x2, y2]) do
    a_squared = :math.pow(x2 - x1, 2)
    b_squared = :math.pow(y2 - y1, 2)
    :math.pow(a_squared + b_squared, 0.5)
  end
end
