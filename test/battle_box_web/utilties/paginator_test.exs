defmodule BattleBoxWeb.Utilites.PaginatorTest do
  import BattleBoxWeb.Utilites.Paginator
  use BattleBox.DataCase
  alias BattleBox.{Bot, Repo}
  import Ecto.Query

  @user_id Ecto.UUID.generate()

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
