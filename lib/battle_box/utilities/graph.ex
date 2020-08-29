defmodule BattleBox.Utilities.Graph do
  defdelegate a_star(start_loc, end_loc, neighbors, heuristic), to: __MODULE__.AStar
end
