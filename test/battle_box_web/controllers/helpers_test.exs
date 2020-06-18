defmodule BattleBoxWeb.Controllers.HelpersTest do
  use BattleBoxWeb.ConnCase
  alias BattleBoxWeb.Controllers.Helpers
  alias BattleBox.{Arena, Bot, User}

  [
    {{Bot, "bot-name"}, "Bot (bot-name) Not Found"},
    {{Bot, "bot-name", "user-name"}, "Bot (bot-name) for User (user-name) Not Found"},
    {{Arena, "arena-name"}, "Arena (arena-name) Not Found"},
    {{Arena, "arena-name", "user-name"}, "Arena (arena-name) for User (user-name) Not Found"},
    {{User, "user-name"}, "User (user-name) Not Found"},
    {"some random message", "some random message"},
  ]
  |> Enum.each(fn {input, expected} ->
    test "rendering 404 for #{inspect(input)} yields #{expected}", %{conn: conn} do
      assert Helpers.render404(conn, unquote(Macro.escape(input))).resp_body =~ unquote(expected)
    end
  end)
end
