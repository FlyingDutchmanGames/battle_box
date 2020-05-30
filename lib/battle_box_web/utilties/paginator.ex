defmodule BattleBoxWeb.Utilites.Paginator do
  import Ecto.Query

  @default_per_page 25
  @max_per_page 50

  def paginate(query, params) do
    %{page: page, per_page: per_page} = pagination_info(params)

    query
    |> limit(^per_page)
    |> offset(^((page - 1) * per_page))
  end

  def pagination_info(params) do
    page =
      case params["page"] do
        nil -> 1
        page -> max(1, to_integer(page))
      end

    per_page =
      with per_page when not is_nil(per_page) <- params["per_page"],
           per_page <- to_integer(per_page),
           per_page when per_page in 0..@max_per_page <- per_page do
        per_page
      else
        _ -> @default_per_page
      end

    adjacent_pages =
      case page do
        page when page < 4 -> 1..7
        page -> (page - 3)..(page + 3)
      end

    %{page: page, per_page: per_page, adjacent_pages: adjacent_pages}
  end

  defp to_integer(str) when is_binary(str), do: String.to_integer(str)
  defp to_integer(num) when is_integer(num), do: num
end
