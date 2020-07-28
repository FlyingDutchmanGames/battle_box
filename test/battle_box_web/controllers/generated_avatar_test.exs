defmodule BattleBoxWeb.GeneratedAvatarControllerTest do
  use BattleBoxWeb.ConnCase

  describe "avatar/1" do
    test "It gives back an svg", %{conn: conn} do
      conn = get(conn, "/generated_avatar/foo")
      assert conn.status == 200
      assert conn.resp_body =~ "foo"
      assert conn.resp_body =~ "xmlns=\"http://www.w3.org/2000/svg\""
      assert get_resp_header(conn, "content-type") == ["image/svg+xml; charset=utf-8"]
    end
  end
end
