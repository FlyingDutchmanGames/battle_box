defmodule BattleBox.Utilities.Graph do
  defmodule State do
    @enforce_keys [:start_loc, :end_loc, :open, :heuristic, :neighbors]
    defstruct [
      :closed,
      :cost_from_start,
      :end_loc,
      :estimated_cost_to_end,
      :heuristic,
      :neighbors,
      :open,
      :start_loc,
      came_from: %{}
    ]
  end

  def a_star(start_loc, end_loc, _neighbors, _heuristic) when start_loc == end_loc do
    {:ok, [start_loc]}
  end

  def a_star(start_loc, end_loc, neighbors, heuristic)
      when is_function(neighbors, 1) and is_function(heuristic, 2),
      do:
        do_a_star(%State{
          start_loc: start_loc,
          end_loc: end_loc,
          open: MapSet.new([start_loc]),
          closed: MapSet.new(),
          neighbors: neighbors,
          heuristic: heuristic,
          estimated_cost_to_end: %{start_loc => heuristic.(start_loc, end_loc)},
          cost_from_start: %{start_loc => 0}
        })

  defp do_a_star(%State{} = state) do
    with {:open_empty?, false} <- {:open_empty?, MapSet.size(state.open) == 0},
         best = Enum.min_by(state.open, &state.estimated_cost_to_end[&1]),
         {:complete?, false} <- {:complete?, best == state.end_loc} do
      neighbors = state.neighbors.(best)

      state = update_in(state.open, &MapSet.delete(&1, best))

      neighbors
      |> Enum.reject(fn neighbor -> neighbor in state.closed end)
      |> Enum.reduce(state, fn neighbor, state ->
        state = update_in(state.open, &MapSet.put(&1, neighbor))
        candidate_cost = state.cost_from_start[best] + 1

        case state.cost_from_start[neighbor] do
          better_cost when not is_nil(better_cost) and better_cost <= candidate_cost ->
            state

          _ ->
            estimated_to_end = candidate_cost + state.heuristic.(neighbor, state.end_loc)
            state = update_in(state.came_from, &Map.put(&1, neighbor, best))
            state = update_in(state.cost_from_start, &Map.put(&1, neighbor, candidate_cost))
            update_in(state.estimated_cost_to_end, &Map.put(&1, neighbor, estimated_to_end))
        end
      end)
      |> do_a_star
    else
      {:open_empty?, true} ->
        {:error, :no_path}

      {:complete?, true} ->
        path = [
          state.end_loc
          | Stream.unfold({state.end_loc, state.came_from}, fn {current, came_from} ->
              if node = came_from[current], do: {node, {node, came_from}}
            end)
            |> Enum.to_list()
        ]

        {:ok, Enum.reverse(path)}
    end
  end
end
