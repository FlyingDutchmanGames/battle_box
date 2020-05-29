defmodule BattleBoxWeb.Utilites.Paginator do
  import Ecto.Query

  @default_per_page 25
  @max_per_page 50

  def paginate(query, params) do
    %{page: page, per_page: per_page} = parse_pagination_params(params)

    query
    |> limit(^per_page)
    |> offset(^((page - 1) * per_page))
  end

  defp parse_pagination_params(params) do
    page =
      case params["page"] do
        nil -> 1
        page -> to_integer(page)
      end

    per_page =
      with per_page when not is_nil(per_page) <- params["per_page"],
           per_page <- to_integer(per_page),
           per_page when per_page in 0..@max_per_page <- per_page do
        per_page
      else
        _ -> @default_per_page
      end

    %{page: page, per_page: per_page}
  end

  defp to_integer(str) when is_binary(str), do: String.to_integer(str)
  defp to_integer(num) when is_integer(num), do: num
end
