defmodule BattleBox.Utilities.PaginatorTest do
  use BattleBox.DataCase
  alias BattleBox.{Bot, Repo}
  import BattleBox.Utilities.Paginator
  import Ecto.Query

  @user_id Ecto.UUID.generate()

  test "pagination_info" do
    assert %{adjacent_pages: 1..7, page: 1, per_page: 25} == pagination_info(%{})
    assert %{adjacent_pages: 7..13, page: 10, per_page: 25} == pagination_info(%{"page" => 10})

    assert %{adjacent_pages: 7..13, page: 10, per_page: 50} ==
             pagination_info(%{"page" => 10, "per_page" => 50})

    assert %{adjacent_pages: 7..13, page: 10, per_page: 25} ==
             pagination_info(%{"page" => 10, "per_page" => 51})

    assert %{adjacent_pages: 1..7, page: 3, per_page: 25} == pagination_info(%{"page" => 3})
    assert %{adjacent_pages: 1..7, page: 4, per_page: 25} == pagination_info(%{"page" => 4})
    assert %{adjacent_pages: 2..8, page: 5, per_page: 25} == pagination_info(%{"page" => 5})
  end

  describe "paginate" do
    test "not asking for a page defaults to 1" do
      create_bots(6)

      assert ~w(A B C D E) == test_pagination_params(%{"per_page" => 5})
      assert ~w(A B C D E) == test_pagination_params(%{"per_page" => "5"})
    end

    test "you can ask for 0 per_page" do
      create_bots(1)

      assert [] == test_pagination_params(%{"per_page" => 0})
      assert [] == test_pagination_params(%{"per_page" => 0, "page" => 10})
    end

    test "you can have a page offset" do
      create_bots(4)

      assert ~w(C D) == test_pagination_params(%{"per_page" => 2, "page" => 2})
    end

    test "asking for a huge page leads to empty" do
      create_bots(2)

      assert [] == test_pagination_params(%{"per_page" => 10, "page" => 10})
    end

    test "page_size is limited to 50 and will go down to 25 when exceeded" do
      create_bots(26)

      assert length(test_pagination_params(%{"per_page" => 51})) == 25
    end

    test "in the case of negative pages, it defaults to page one" do
      create_bots(1)
      assert ["A"] == test_pagination_params(%{"page" => -1})
    end
  end

  defp create_bots(number) do
    ?A..?z
    |> Enum.take(number)
    |> Enum.map(fn char ->
      %Bot{name: "#{[char]}", user_id: @user_id}
      |> Repo.insert!()
    end)
  end

  defp test_pagination_params(params) do
    Bot
    |> order_by(:name)
    |> paginate(params)
    |> select([bot], bot.name)
    |> Repo.all()
  end
end
