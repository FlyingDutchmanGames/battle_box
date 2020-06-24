defmodule BattleBoxWeb.DocsControllerTest do
  use BattleBoxWeb.ConnCase, async: false
  import BattleBoxWeb.DocsController, only: [paths: 0]

  for path <- paths() do
    test "doc (#{Enum.join(["docs" | path], "/")}) renders correctly", %{conn: conn} do
      path = Routes.docs_path(conn, :docs, unquote(Macro.escape(path)))
      conn = get(conn, path)
      assert html_response(conn, 200)
    end
  end
end
